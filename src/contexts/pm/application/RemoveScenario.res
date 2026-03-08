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
  scenarioId: string,
}

@genType
type removedEvent = {
  taskId: string,
  organizationId: string,
  scenarioId: string,
  removedBy: string,
  sessionId: string,
  expectedVersion: int,
  version: int,
  occurredAt: float,
}

@genType
type taskInfo = {
  version: int,
  kind: string,
}

@genType
type dependencies = {
  now: unit => float,
  loadTask: string => Promise.t<option<taskInfo>>,
  appendEvent: removedEvent => Promise.t<unit>,
}

@genType
type error = [
  | #Forbidden
  | #TaskNotFound
  | #NotAUserStory
]

let authorize = (command: command) =>
  if hasAllowedRole(command.session.roles) {
    Ok(command)
  } else {
    Error(#Forbidden)
  }

let requireUserStory = (task: taskInfo) =>
  if task.kind == "user_story" {
    Ok(task)
  } else {
    Error(#NotAUserStory)
  }

@genType
let execute = (deps: dependencies, command: command): Promise.t<result<unit, error>> =>
  authorize(command)
  ->AsyncResult.fromResult
  ->AsyncResult.flatMap(cmd =>
    deps.loadTask(cmd.taskId)
    ->Promise.thenResolve(opt =>
      switch opt {
      | None => Error(#TaskNotFound)
      | Some(task) => requireUserStory(task)
      }
    )
  )
  ->AsyncResult.flatMap(task => {
    let event: removedEvent = {
      taskId: command.taskId,
      organizationId: command.session.organizationId,
      scenarioId: command.scenarioId,
      removedBy: command.session.userId,
      sessionId: command.session.sessionId,
      expectedVersion: task.version,
      version: task.version + 1,
      occurredAt: deps.now(),
    }
    deps.appendEvent(event)->Promise.thenResolve(_ => Ok())
  })
