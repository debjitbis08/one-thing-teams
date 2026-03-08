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
  userId: string,
}

@genType
type assignedEvent = {
  taskId: string,
  organizationId: string,
  assigneeUserId: string,
  assignedBy: string,
  sessionId: string,
  expectedVersion: int,
  version: int,
  occurredAt: float,
}

@genType
type taskInfo = {
  version: int,
}

@genType
type dependencies = {
  now: unit => float,
  loadTask: string => Promise.t<option<taskInfo>>,
  memberExists: string => Promise.t<bool>,
  appendEvent: assignedEvent => Promise.t<unit>,
}

@genType
type error = [
  | #Forbidden
  | #TaskNotFound
  | #MemberNotFound
]

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
    deps.memberExists(command.userId)
    ->Promise.thenResolve(exists =>
      if exists { Ok(task) } else { Error(#MemberNotFound) }
    )
  )
  ->AsyncResult.flatMap(task => {
    let event: assignedEvent = {
      taskId: command.taskId,
      organizationId: command.session.organizationId,
      assigneeUserId: command.userId,
      assignedBy: command.session.userId,
      sessionId: command.session.sessionId,
      expectedVersion: task.version,
      version: task.version + 1,
      occurredAt: deps.now(),
    }
    deps.appendEvent(event)->Promise.thenResolve(_ => Ok())
  })
