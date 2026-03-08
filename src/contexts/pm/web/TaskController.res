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
    | Some(s) if String.trim(s) != "" => Some(Some(s))
    | _ => None
    }
  | None => None
  }

// --- Update Task Status ---

type updateStatusDependencies = {
  appendEvent: UpdateTaskStatus.statusUpdatedEvent => Promise.t<unit>,
  loadTask: string => Promise.t<option<UpdateTaskStatus.taskInfo>>,
  now: unit => float,
}

type updateStatusContext = {
  request: Fetch.Request.t,
  session: option<UpdateTaskStatus.session>,
  taskId: string,
}

let patchStatus = (
  deps: updateStatusDependencies,
  ctx: updateStatusContext,
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
        switch decodeStringField(dict, "status") {
        | None =>
          Promise.resolve(errorResponse(SystemError.validation("Field 'status' is required")))
        | Some(status) =>
          let command: UpdateTaskStatus.command = {
            session,
            taskId: ctx.taskId,
            status,
          }
          let appDeps: UpdateTaskStatus.dependencies = {
            now: deps.now,
            loadTask: deps.loadTask,
            appendEvent: deps.appendEvent,
          }
          UpdateTaskStatus.execute(appDeps, command)
          ->Promise.then(result =>
            switch result {
            | Ok(_) => Promise.resolve(makeResponse(~status=200, encodeSuccess()))
            | Error(#Forbidden) =>
              Promise.resolve(errorResponse(SystemError.forbidden("Forbidden")))
            | Error(#TaskNotFound) =>
              Promise.resolve(errorResponse(SystemError.notFound("Task not found")))
            | Error(#InvalidStatus(s)) =>
              Promise.resolve(
                errorResponse(
                  SystemError.validation(
                    "Invalid status: " ++
                    s ++
                    ". Must be 'todo', 'doing', 'stuck', 'done', or 'pruned'",
                  ),
                ),
              )
            | Error(#InvalidTransition(from, to_)) =>
              Promise.resolve(
                errorResponse(
                  SystemError.validation(
                    "Cannot transition from '" ++ from ++ "' to '" ++ to_ ++ "'",
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
    Js.log2("Update task status controller unexpected error", error)
    Promise.resolve(errorResponse(SystemError.internal("Unable to update task status")))
  })
}

@genType
let patchStatusJs = patchStatus

// --- Update Task ---

type updateTaskDependencies = {
  appendEvent: UpdateTask.updatedEvent => Promise.t<unit>,
  loadTask: string => Promise.t<option<UpdateTask.taskInfo>>,
  now: unit => float,
}

type updateTaskContext = {
  request: Fetch.Request.t,
  session: option<UpdateTask.session>,
  taskId: string,
}

let patchTask = (deps: updateTaskDependencies, ctx: updateTaskContext): Promise.t<response> => {
  switch ctx.session {
  | None => Promise.resolve(errorResponse(SystemError.unauthorized("Unauthorized")))
  | Some(session) =>
    Fetch.Request.json(ctx.request)
    ->Promise.then(json =>
      switch JSON.Decode.object(json) {
      | None =>
        Promise.resolve(errorResponse(SystemError.validation("Request body must be a JSON object")))
      | Some(dict) =>
        let title = decodeOptionalStringField(dict, "title")->Belt.Option.flatMap(v => v)
        let description = decodeOptionalStringField(dict, "description")->Belt.Option.flatMap(v => v)
        let command: UpdateTask.command = {
          session,
          taskId: ctx.taskId,
          title,
          description,
        }
        let appDeps: UpdateTask.dependencies = {
          now: deps.now,
          loadTask: deps.loadTask,
          appendEvent: deps.appendEvent,
        }
        UpdateTask.execute(appDeps, command)
        ->Promise.then(result =>
          switch result {
          | Ok(_) => Promise.resolve(makeResponse(~status=200, encodeSuccess()))
          | Error(#Forbidden) =>
            Promise.resolve(errorResponse(SystemError.forbidden("Forbidden")))
          | Error(#TaskNotFound) =>
            Promise.resolve(errorResponse(SystemError.notFound("Task not found")))
          | Error(#InvalidTitle(t)) =>
            Promise.resolve(
              errorResponse(SystemError.validation("Invalid task title: " ++ t)),
            )
          | Error(#NoChanges) =>
            Promise.resolve(
              errorResponse(
                SystemError.validation("At least one field (title or description) must be provided"),
              ),
            )
          }
        )
      }
    )
    ->Promise.catch(_error =>
      Promise.resolve(errorResponse(SystemError.validation("Request body must be valid JSON")))
    )
  }
  ->Promise.catch(error => {
    Js.log2("Update task controller unexpected error", error)
    Promise.resolve(errorResponse(SystemError.internal("Unable to update task")))
  })
}

@genType
let patchTaskJs = patchTask

// --- Assign Task ---

type assignDependencies = {
  appendEvent: AssignTask.assignedEvent => Promise.t<unit>,
  loadTask: string => Promise.t<option<AssignTask.taskInfo>>,
  memberExists: string => Promise.t<bool>,
  now: unit => float,
}

type assignContext = {
  request: Fetch.Request.t,
  session: option<AssignTask.session>,
  taskId: string,
}

let postAssign = (deps: assignDependencies, ctx: assignContext): Promise.t<response> => {
  switch ctx.session {
  | None => Promise.resolve(errorResponse(SystemError.unauthorized("Unauthorized")))
  | Some(session) =>
    Fetch.Request.json(ctx.request)
    ->Promise.then(json =>
      switch JSON.Decode.object(json) {
      | None =>
        Promise.resolve(errorResponse(SystemError.validation("Request body must be a JSON object")))
      | Some(dict) =>
        switch decodeStringField(dict, "userId") {
        | None =>
          Promise.resolve(errorResponse(SystemError.validation("Field 'userId' is required")))
        | Some(userId) =>
          let command: AssignTask.command = {
            session,
            taskId: ctx.taskId,
            userId,
          }
          let appDeps: AssignTask.dependencies = {
            now: deps.now,
            loadTask: deps.loadTask,
            memberExists: deps.memberExists,
            appendEvent: deps.appendEvent,
          }
          AssignTask.execute(appDeps, command)
          ->Promise.then(result =>
            switch result {
            | Ok(_) => Promise.resolve(makeResponse(~status=200, encodeSuccess()))
            | Error(#Forbidden) =>
              Promise.resolve(errorResponse(SystemError.forbidden("Forbidden")))
            | Error(#TaskNotFound) =>
              Promise.resolve(errorResponse(SystemError.notFound("Task not found")))
            | Error(#MemberNotFound) =>
              Promise.resolve(errorResponse(SystemError.notFound("Member not found")))
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
    Js.log2("Assign task controller unexpected error", error)
    Promise.resolve(errorResponse(SystemError.internal("Unable to assign task")))
  })
}

@genType
let postAssignJs = postAssign

// --- Unassign Task ---

type unassignDependencies = {
  appendEvent: UnassignTask.unassignedEvent => Promise.t<unit>,
  loadTask: string => Promise.t<option<UnassignTask.taskInfo>>,
  now: unit => float,
}

type unassignContext = {
  session: option<UnassignTask.session>,
  taskId: string,
  userId: string,
}

let deleteAssign = (deps: unassignDependencies, ctx: unassignContext): Promise.t<response> => {
  switch ctx.session {
  | None => Promise.resolve(errorResponse(SystemError.unauthorized("Unauthorized")))
  | Some(session) =>
    let command: UnassignTask.command = {
      session,
      taskId: ctx.taskId,
      userId: ctx.userId,
    }
    let appDeps: UnassignTask.dependencies = {
      now: deps.now,
      loadTask: deps.loadTask,
      appendEvent: deps.appendEvent,
    }
    UnassignTask.execute(appDeps, command)
    ->Promise.then(result =>
      switch result {
      | Ok(_) => Promise.resolve(makeResponse(~status=200, encodeSuccess()))
      | Error(#Forbidden) =>
        Promise.resolve(errorResponse(SystemError.forbidden("Forbidden")))
      | Error(#TaskNotFound) =>
        Promise.resolve(errorResponse(SystemError.notFound("Task not found")))
      }
    )
  }
  ->Promise.catch(error => {
    Js.log2("Unassign task controller unexpected error", error)
    Promise.resolve(errorResponse(SystemError.internal("Unable to unassign task")))
  })
}

@genType
let deleteAssignJs = deleteAssign
