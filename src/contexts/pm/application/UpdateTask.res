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
  title: option<string>,
  description: option<string>,
}

@genType
type updatedEvent = {
  taskId: string,
  organizationId: string,
  title: option<string>,
  description: option<string>,
  updatedBy: string,
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
  appendEvent: updatedEvent => Promise.t<unit>,
}

@genType
type error = [
  | #Forbidden
  | #TaskNotFound
  | #InvalidTitle(string)
  | #NoChanges
]

let authorize = (command: command) =>
  if hasAllowedRole(command.session.roles) {
    Ok(command)
  } else {
    Error(#Forbidden)
  }

let validateChanges = (command: command) =>
  switch (command.title, command.description) {
  | (None, None) => Error(#NoChanges)
  | _ => Ok()
  }

let validateTitle = (command: command) =>
  switch command.title {
  | None => Ok()
  | Some(title) =>
    switch TaskTitle.make(title) {
    | Ok(_) => Ok()
    | Error(_) => Error(#InvalidTitle(title))
    }
  }

@genType
let execute = (deps: dependencies, command: command): Promise.t<result<unit, error>> =>
  authorize(command)
  ->AsyncResult.fromResult
  ->AsyncResult.flatMap(_ => validateChanges(command)->AsyncResult.fromResult)
  ->AsyncResult.flatMap(_ => validateTitle(command)->AsyncResult.fromResult)
  ->AsyncResult.flatMap(_ =>
    deps.loadTask(command.taskId)
    ->Promise.thenResolve(opt =>
      switch opt {
      | None => Error(#TaskNotFound)
      | Some(task) => Ok(task)
      }
    )
  )
  ->AsyncResult.flatMap(task => {
    let event: updatedEvent = {
      taskId: command.taskId,
      organizationId: command.session.organizationId,
      title: command.title,
      description: command.description,
      updatedBy: command.session.userId,
      sessionId: command.session.sessionId,
      expectedVersion: task.version,
      version: task.version + 1,
      occurredAt: deps.now(),
    }
    deps.appendEvent(event)->Promise.thenResolve(_ => Ok())
  })
