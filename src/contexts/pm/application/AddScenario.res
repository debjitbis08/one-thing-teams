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
  title: string,
}

@genType
type addedEvent = {
  taskId: string,
  organizationId: string,
  scenarioId: string,
  title: string,
  addedBy: string,
  sessionId: string,
  expectedVersion: int,
  version: int,
  occurredAt: float,
}

@genType
type addedResult = {
  scenarioId: string,
  title: string,
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
  appendEvent: addedEvent => Promise.t<unit>,
}

@genType
type error = [
  | #Forbidden
  | #TaskNotFound
  | #NotAUserStory
  | #InvalidTitle(string)
]

let authorize = (command: command) =>
  if hasAllowedRole(command.session.roles) {
    Ok(command)
  } else {
    Error(#Forbidden)
  }

let validateTitle = (command: command) =>
  switch TaskTitle.make(command.title) {
  | Ok(validTitle) => Ok((command, validTitle))
  | Error(_) => Error(#InvalidTitle(command.title))
  }

let requireUserStory = (task: taskInfo) =>
  if task.kind == "user_story" {
    Ok(task)
  } else {
    Error(#NotAUserStory)
  }

@genType
let execute = (deps: dependencies, command: command): Promise.t<result<addedResult, error>> =>
  authorize(command)
  ->AsyncResult.fromResult
  ->AsyncResult.flatMap(cmd => validateTitle(cmd)->AsyncResult.fromResult)
  ->AsyncResult.flatMap(((cmd, validTitle)) =>
    deps.loadTask(cmd.taskId)
    ->Promise.thenResolve(opt =>
      switch opt {
      | None => Error(#TaskNotFound)
      | Some(task) => requireUserStory(task)->Belt.Result.map(_ => (task, validTitle))
      }
    )
  )
  ->AsyncResult.flatMap(((task, validTitle)) => {
    let scenarioId = UUIDv7.value(UUIDv7.gen())
    let event: addedEvent = {
      taskId: command.taskId,
      organizationId: command.session.organizationId,
      scenarioId,
      title: TaskTitle.value(validTitle),
      addedBy: command.session.userId,
      sessionId: command.session.sessionId,
      expectedVersion: task.version,
      version: task.version + 1,
      occurredAt: deps.now(),
    }
    deps.appendEvent(event)->Promise.thenResolve(_ => Ok({scenarioId, title: event.title}))
  })
