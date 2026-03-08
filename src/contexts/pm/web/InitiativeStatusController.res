module Dict = RescriptCore.Dict
module JSON = RescriptCore.JSON
module Promise = RescriptCore.Promise
module Encode = RescriptCore.JSON.Encode

type response = {
  status: int,
  body: JSON.t,
}

let makeResponse = (~status, body) => {status, body}

let errorResponse = error =>
  makeResponse(~status=SystemError.httpStatus(error), SystemError.encode(error))

let encodeSuccess = () => {
  let dict = Dict.make()
  dict->Dict.set("success", Encode.bool(true))
  Encode.object(dict)
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

// --- Update Progress Status ---

type progressDependencies = {
  appendEvent: UpdateProgressStatus.progressStatusUpdatedEvent => Promise.t<unit>,
  loadInitiative: string => Promise.t<option<UpdateProgressStatus.initiativeInfo>>,
  now: unit => float,
}

type progressContext = {
  request: Fetch.Request.t,
  session: option<UpdateProgressStatus.session>,
  initiativeId: string,
}

let patchProgress = (
  deps: progressDependencies,
  ctx: progressContext,
): Promise.t<response> => {
  switch ctx.session {
  | None => Promise.resolve(errorResponse(SystemError.unauthorized("Unauthorized")))
  | Some(session) =>
    Fetch.Request.json(ctx.request)
    ->Promise.then(json =>
      switch JSON.Decode.object(json) {
      | None =>
        Promise.resolve(errorResponse(SystemError.validation("Request body must be a JSON object")))
      | Some(dict) =>
        switch decodeStringField(dict, "progressStatus") {
        | None =>
          Promise.resolve(
            errorResponse(SystemError.validation("Field 'progressStatus' is required")),
          )
        | Some(progressStatus) =>
          let command: UpdateProgressStatus.command = {
            session,
            initiativeId: ctx.initiativeId,
            progressStatus,
          }
          let appDeps: UpdateProgressStatus.dependencies = {
            now: deps.now,
            loadInitiative: deps.loadInitiative,
            appendEvent: deps.appendEvent,
          }
          UpdateProgressStatus.execute(appDeps, command)
          ->Promise.then(result =>
            switch result {
            | Ok(_) => Promise.resolve(makeResponse(~status=200, encodeSuccess()))
            | Error(#Forbidden) =>
              Promise.resolve(errorResponse(SystemError.forbidden("Forbidden")))
            | Error(#InitiativeNotFound) =>
              Promise.resolve(errorResponse(SystemError.notFound("Initiative not found")))
            | Error(#InvalidProgressStatus(s)) =>
              Promise.resolve(
                errorResponse(
                  SystemError.validation(
                    "Invalid progress status: " ++
                    s ++
                    ". Must be 'thinking', 'trying', 'building', 'finishing', 'deploying', 'distributing', or 'stuck'",
                  ),
                ),
              )
            }
          )
        }
      }
    )
    ->Promise.catch(_error =>
      Promise.resolve(errorResponse(SystemError.validation("Request body must be valid JSON")))
    )
  }
  ->Promise.catch(error => {
    Js.log2("Update progress status controller unexpected error", error)
    Promise.resolve(errorResponse(SystemError.internal("Unable to update progress status")))
  })
}

@genType
let patchProgressJs = patchProgress

// --- Update Lifecycle Status ---

type lifecycleDependencies = {
  appendEvent: UpdateLifecycleStatus.lifecycleStatusUpdatedEvent => Promise.t<unit>,
  loadInitiative: string => Promise.t<option<UpdateLifecycleStatus.initiativeInfo>>,
  now: unit => float,
}

type lifecycleContext = {
  request: Fetch.Request.t,
  session: option<UpdateLifecycleStatus.session>,
  initiativeId: string,
}

let patchLifecycle = (
  deps: lifecycleDependencies,
  ctx: lifecycleContext,
): Promise.t<response> => {
  switch ctx.session {
  | None => Promise.resolve(errorResponse(SystemError.unauthorized("Unauthorized")))
  | Some(session) =>
    Fetch.Request.json(ctx.request)
    ->Promise.then(json =>
      switch JSON.Decode.object(json) {
      | None =>
        Promise.resolve(errorResponse(SystemError.validation("Request body must be a JSON object")))
      | Some(dict) =>
        switch decodeStringField(dict, "lifecycleStatus") {
        | None =>
          Promise.resolve(
            errorResponse(SystemError.validation("Field 'lifecycleStatus' is required")),
          )
        | Some(lifecycleStatus) =>
          let doneEvidence = decodeOptionalStringField(dict, "doneEvidence")
          let outcomeNotes = decodeOptionalStringField(dict, "outcomeNotes")
          let command: UpdateLifecycleStatus.command = {
            session,
            initiativeId: ctx.initiativeId,
            lifecycleStatus,
            doneEvidence,
            outcomeNotes,
          }
          let appDeps: UpdateLifecycleStatus.dependencies = {
            now: deps.now,
            loadInitiative: deps.loadInitiative,
            appendEvent: deps.appendEvent,
          }
          UpdateLifecycleStatus.execute(appDeps, command)
          ->Promise.then(result =>
            switch result {
            | Ok(_) => Promise.resolve(makeResponse(~status=200, encodeSuccess()))
            | Error(#Forbidden) =>
              Promise.resolve(errorResponse(SystemError.forbidden("Forbidden")))
            | Error(#InitiativeNotFound) =>
              Promise.resolve(errorResponse(SystemError.notFound("Initiative not found")))
            | Error(#InvalidLifecycleStatus(s)) =>
              Promise.resolve(
                errorResponse(
                  SystemError.validation(
                    "Invalid lifecycle status: " ++
                    s ++
                    ". Must be 'waiting', 'active', 'done', or 'abandoned'",
                  ),
                ),
              )
            }
          )
        }
      }
    )
    ->Promise.catch(_error =>
      Promise.resolve(errorResponse(SystemError.validation("Request body must be valid JSON")))
    )
  }
  ->Promise.catch(error => {
    Js.log2("Update lifecycle status controller unexpected error", error)
    Promise.resolve(errorResponse(SystemError.internal("Unable to update lifecycle status")))
  })
}

@genType
let patchLifecycleJs = patchLifecycle
