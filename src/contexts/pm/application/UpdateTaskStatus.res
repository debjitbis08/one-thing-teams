module Promise = RescriptCore.Promise

let hasAllowedRole = roles =>
  roles->Belt.Array.some(role => role == "OWNER" || role == "ADMIN")

type session = {
  sessionId: string,
  userId: string,
  organizationId: string,
  roles: array<string>,
}

@genType
type command = {
  session: session,
  taskId: string,
  status: string,
}

@genType
type statusUpdatedEvent = {
  taskId: string,
  organizationId: string,
  status: string,
  previousStatus: string,
  updatedBy: string,
  sessionId: string,
  expectedVersion: int,
  version: int,
  occurredAt: float,
}

@genType
type taskInfo = {
  version: int,
  kind: string,
  status: string,
}

@genType
type dependencies = {
  now: unit => float,
  loadTask: string => Promise.t<option<taskInfo>>,
  appendEvent: statusUpdatedEvent => Promise.t<unit>,
}

@genType
type error = [
  | #Forbidden
  | #TaskNotFound
  | #InvalidStatus(string)
  | #InvalidTransition(string, string)
]

let validStatuses = ["todo", "doing", "stuck", "done", "pruned"]

let validateStatus = (status: string) =>
  if validStatuses->Belt.Array.some(s => s == status) {
    Ok(status)
  } else {
    Error(#InvalidStatus(status))
  }

let allowedTransitions = (from: string): array<string> =>
  switch from {
  | "todo" => ["doing", "stuck", "pruned"]
  | "doing" => ["stuck", "done"]
  | "stuck" => ["doing", "done"]
  | "done" => ["doing"]
  | _ => []
  }

let validateTransition = (~from: string, ~to_: string) =>
  if allowedTransitions(from)->Belt.Array.some(s => s == to_) {
    Ok()
  } else {
    Error(#InvalidTransition(from, to_))
  }

let authorize = (command: command) =>
  if hasAllowedRole(command.session.roles) {
    Ok(command)
  } else {
    Error(#Forbidden)
  }

@genType
let execute = (deps: dependencies, command: command): Promise.t<result<unit, error>> =>
  authorize(command)
  ->AsyncResult.fromResult
  ->AsyncResult.flatMap(_ => validateStatus(command.status)->AsyncResult.fromResult)
  ->AsyncResult.flatMap(_ =>
    deps.loadTask(command.taskId)
    ->Promise.thenResolve(opt =>
      switch opt {
      | None => Error(#TaskNotFound)
      | Some(task) => Ok(task)
      }
    )
  )
  ->AsyncResult.flatMap(task =>
    validateTransition(~from=task.status, ~to_=command.status)
    ->AsyncResult.fromResult
    ->AsyncResult.map(_ => task)
  )
  ->AsyncResult.flatMap(task => {
    let event: statusUpdatedEvent = {
      taskId: command.taskId,
      organizationId: command.session.organizationId,
      status: command.status,
      previousStatus: task.status,
      updatedBy: command.session.userId,
      sessionId: command.session.sessionId,
      expectedVersion: task.version,
      version: task.version + 1,
      occurredAt: deps.now(),
    }
    deps.appendEvent(event)->Promise.thenResolve(_ => Ok())
  })
