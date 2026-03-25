module Dict = RescriptCore.Dict
module JSON = RescriptCore.JSON
module Promise = RescriptCore.Promise
module Encode = RescriptCore.JSON.Encode

type addSession = AddScenario.session
type removeSession = RemoveScenario.session

type addDependencies = {
  appendEvent: AddScenario.addedEvent => Promise.t<unit>,
  loadTask: string => Promise.t<option<AddScenario.taskInfo>>,
  now: unit => float,
}

type removeDependencies = {
  appendEvent: RemoveScenario.removedEvent => Promise.t<unit>,
  loadTask: string => Promise.t<option<RemoveScenario.taskInfo>>,
  now: unit => float,
}

type postContext = {
  request: Fetch.Request.t,
  session: option<addSession>,
  taskId: string,
}

type deleteContext = {
  session: option<removeSession>,
  taskId: string,
  scenarioId: string,
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

let makeResponse = (~status, body) => {status, body}

let errorResponse = error => makeResponse(~status=SystemError.httpStatus(error), SystemError.encode(error))

let encodeSuccess = (result: AddScenario.addedResult) => {
  let dict = Dict.make()
  dict->Dict.set("scenarioId", Encode.string(result.scenarioId))
  dict->Dict.set("title", Encode.string(result.title))
  Encode.object(dict)
}

let encodeDeleteSuccess = () => {
  let dict = Dict.make()
  dict->Dict.set("success", Encode.bool(true))
  Encode.object(dict)
}

let post = (deps: addDependencies, ctx: postContext): Promise.t<response> => {
  switch ctx.session {
  | None => Promise.resolve(errorResponse(SystemError.unauthorized("Unauthorized")))
  | Some(session) =>
    Fetch.Request.json(ctx.request)
    ->Promise.then(json =>
      switch JSON.Decode.object(json) {
      | None => Promise.resolve(errorResponse(SystemError.validation("Request body must be a JSON object")))
      | Some(dict) =>
        switch decodeStringField(dict, "title") {
        | None =>
          Promise.resolve(errorResponse(SystemError.validation("Field 'title' is required")))
        | Some(title) =>
          let command: AddScenario.command = {
            session,
            taskId: ctx.taskId,
            title,
          }
          let appDeps: AddScenario.dependencies = {
            now: deps.now,
            loadTask: deps.loadTask,
            appendEvent: deps.appendEvent,
          }
          AddScenario.execute(appDeps, command)
          ->Promise.then(result =>
            switch result {
            | Ok(added) => Promise.resolve(makeResponse(~status=201, encodeSuccess(added)))
            | Error(#Forbidden) =>
              Promise.resolve(errorResponse(SystemError.forbidden("Forbidden")))
            | Error(#TaskNotFound) =>
              Promise.resolve(errorResponse(SystemError.notFound("Task not found")))
            | Error(#NotAUserStory) =>
              Promise.resolve(errorResponse(SystemError.validation("Scenarios can only be added to user stories")))
            | Error(#InvalidTitle(t)) =>
              Promise.resolve(errorResponse(SystemError.validation("Invalid scenario title: " ++ t)))
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
    Js.log2("Add scenario controller unexpected error", error)
    Promise.resolve(errorResponse(SystemError.internal("Unable to add scenario")))
  })
}

let delete = (deps: removeDependencies, ctx: deleteContext): Promise.t<response> => {
  switch ctx.session {
  | None => Promise.resolve(errorResponse(SystemError.unauthorized("Unauthorized")))
  | Some(session) =>
    let command: RemoveScenario.command = {
      session,
      taskId: ctx.taskId,
      scenarioId: ctx.scenarioId,
    }
    let appDeps: RemoveScenario.dependencies = {
      now: deps.now,
      loadTask: deps.loadTask,
      appendEvent: deps.appendEvent,
    }
    RemoveScenario.execute(appDeps, command)
    ->Promise.then(result =>
      switch result {
      | Ok(_) => Promise.resolve(makeResponse(~status=200, encodeDeleteSuccess()))
      | Error(#Forbidden) =>
        Promise.resolve(errorResponse(SystemError.forbidden("Forbidden")))
      | Error(#TaskNotFound) =>
        Promise.resolve(errorResponse(SystemError.notFound("Task not found")))
      | Error(#NotAUserStory) =>
        Promise.resolve(errorResponse(SystemError.validation("Scenarios can only be removed from user stories")))
      }
    )
  }
  ->Promise.catch(error => {
    Js.log2("Remove scenario controller unexpected error", error)
    Promise.resolve(errorResponse(SystemError.internal("Unable to remove scenario")))
  })
}

@genType
let postJs = post

@genType
let deleteJs = delete
