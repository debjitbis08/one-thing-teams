module Dict = RescriptCore.Dict
module JSON = RescriptCore.JSON
module Promise = RescriptCore.Promise
module Encode = RescriptCore.JSON.Encode
module CreateTask = CreateTask

type session = CreateTask.session

type dependencies = CreateTask.dependencies

type astroContext = {
  request: Fetch.Request.t,
  session: option<session>,
}

type response = {
  status: int,
  body: JSON.t,
}

let decodeStringField = (dict, key) =>
  switch Dict.get(dict, key) {
  | Some(value) => JSON.Decode.string(value)
  | None => None
  }

let decodeOptionalStringField = (dict, key) =>
  switch Dict.get(dict, key) {
  | Some(value) =>
    switch JSON.Decode.string(value) {
    | Some(s) if String.trim(s) != "" => Some(s)
    | _ => None
    }
  | None => None
  }

let decodeScenarios = (dict): option<array<CreateTask.scenarioInput>> =>
  switch Dict.get(dict, "scenarios") {
  | None => None
  | Some(value) =>
    switch JSON.Decode.array(value) {
    | None => None
    | Some(items) =>
      let parsed = items->Belt.Array.keepMap(item =>
        switch JSON.Decode.object(item) {
        | None => None
        | Some(sDict) =>
          switch decodeStringField(sDict, "title") {
          | None => None
          | Some(title) =>
            let criteria = switch Dict.get(sDict, "acceptanceCriteria") {
            | None => []
            | Some(arr) =>
              switch JSON.Decode.array(arr) {
              | None => []
              | Some(items) => items->Belt.Array.keepMap(JSON.Decode.string)
              }
            }
            Some({CreateTask.title: title, acceptanceCriteria: criteria})
          }
        }
      )
      Some(parsed)
    }
  }

let makeResponse = (~status, body) => {status, body}

let errorResponse = error => makeResponse(~status=SystemError.httpStatus(error), SystemError.encode(error))

let encodeSuccess = (result: CreateTask.createdResult) => {
  let dict = Dict.make()
  dict->Dict.set("taskId", Encode.string(result.taskId))
  dict->Dict.set("title", Encode.string(result.title))
  dict->Dict.set("kind", Encode.string(result.kind))
  Encode.object(dict)
}

let post = (deps: dependencies, ctx: astroContext): Promise.t<response> => {
  switch ctx.session {
  | None => Promise.resolve(errorResponse(SystemError.unauthorized("Unauthorized")))
  | Some(session) =>
    Fetch.Request.json(ctx.request)
    ->Promise.then(json =>
      switch JSON.Decode.object(json) {
      | None => Promise.resolve(errorResponse(SystemError.validation("Request body must be a JSON object")))
      | Some(dict) =>
        switch (
          decodeStringField(dict, "title"),
          decodeStringField(dict, "kind"),
        ) {
        | (Some(title), Some(kind)) =>
          let command: CreateTask.command = {
            session,
            title,
            description: decodeOptionalStringField(dict, "description"),
            kind,
            initiativeId: decodeStringField(dict, "initiativeId"),
            productId: decodeStringField(dict, "productId"),
            emergencyId: decodeStringField(dict, "emergencyId"),
            scenarios: decodeScenarios(dict),
          }
          CreateTask.execute(deps, command)
          ->Promise.then(result =>
            switch result {
            | Ok(created) => Promise.resolve(makeResponse(~status=201, encodeSuccess(created)))
            | Error(#Forbidden) =>
              Promise.resolve(errorResponse(SystemError.forbidden("Forbidden")))
            | Error(#InvalidTitle(t)) =>
              Promise.resolve(errorResponse(SystemError.validation("Invalid task title: " ++ t)))
            | Error(#InvalidKind(k)) =>
              Promise.resolve(errorResponse(SystemError.validation("Invalid kind: " ++ k ++ ". Must be 'initiative_task', 'user_story', 'emergency', or 'support'")))
            | Error(#InitiativeNotFound) =>
              Promise.resolve(errorResponse(SystemError.notFound("Initiative not found")))
            | Error(#ProductNotFound) =>
              Promise.resolve(errorResponse(SystemError.notFound("Product not found")))
            | Error(#EmergencyNotFound) =>
              Promise.resolve(errorResponse(SystemError.notFound("Emergency not found")))
            | Error(#MissingInitiativeId) =>
              Promise.resolve(errorResponse(SystemError.validation("Field 'initiativeId' is required for initiative tasks and user stories")))
            | Error(#MissingProductId) =>
              Promise.resolve(errorResponse(SystemError.validation("Field 'productId' is required for support tasks")))
            | Error(#MissingEmergencyId) =>
              Promise.resolve(errorResponse(SystemError.validation("Field 'emergencyId' is required for emergency tasks")))
            }
          )
        | (None, _) =>
          Promise.resolve(errorResponse(SystemError.validation("Field 'title' is required")))
        | (_, None) =>
          Promise.resolve(errorResponse(SystemError.validation("Field 'kind' is required")))
        }
      }
    )
    ->Promise.catch(_error =>
      Promise.resolve(errorResponse(SystemError.validation("Request body must be valid JSON")))
    )
  }
  ->Promise.catch(error => {
    Js.log2("Create task controller unexpected error", error)
    Promise.resolve(errorResponse(SystemError.internal("Unable to create task")))
  })
}

@genType
let postJs = post
