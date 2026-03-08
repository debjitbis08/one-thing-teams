module Promise = RescriptCore.Promise
module Array = Belt.Array

let hasAllowedRole = roles => roles->Array.some(role => role == "OWNER" || role == "ADMIN")

type session = {
  sessionId: string,
  userId: string,
  organizationId: string,
  roles: array<string>,
}

type scenarioInput = {
  title: string,
  acceptanceCriteria: array<string>,
}

@genType
type command = {
  session: session,
  title: string,
  description: option<string>,
  kind: string,
  initiativeId: option<string>,
  productId: option<string>,
  emergencyId: option<string>,
  scenarios: option<array<scenarioInput>>,
}

@genType
type createdEvent = {
  taskId: string,
  organizationId: string,
  title: string,
  description: option<string>,
  kind: string,
  initiativeId: option<string>,
  productId: option<string>,
  emergencyId: option<string>,
  scenarios: option<array<scenarioInput>>,
  createdBy: string,
  occurredAt: float,
}

@genType
type createdResult = {
  taskId: string,
  title: string,
  kind: string,
}

@genType
type dependencies = {
  now: unit => float,
  initiativeExists: string => Promise.t<bool>,
  productExists: string => Promise.t<bool>,
  emergencyExists: string => Promise.t<bool>,
  appendEvent: createdEvent => Promise.t<unit>,
}

@genType
type error = [
  | #Forbidden
  | #InvalidTitle(string)
  | #InvalidKind(string)
  | #InitiativeNotFound
  | #ProductNotFound
  | #EmergencyNotFound
  | #MissingInitiativeId
  | #MissingProductId
  | #MissingEmergencyId
]

let validateContext = (command: command): result<unit, error> =>
  switch command.kind {
  | "initiative_task" =>
    switch command.initiativeId {
    | None => Error(#MissingInitiativeId)
    | Some(_) => Ok()
    }
  | "user_story" =>
    switch command.initiativeId {
    | None => Error(#MissingInitiativeId)
    | Some(_) => Ok()
    }
  | "emergency" =>
    switch command.emergencyId {
    | None => Error(#MissingEmergencyId)
    | Some(_) => Ok()
    }
  | "support" =>
    switch command.productId {
    | None => Error(#MissingProductId)
    | Some(_) => Ok()
    }
  | other => Error(#InvalidKind(other))
  }

let verifyExists = (deps: dependencies, command: command): Promise.t<result<unit, error>> =>
  switch command.kind {
  | "initiative_task" | "user_story" =>
    switch command.initiativeId {
    | Some(id) =>
      deps.initiativeExists(id)->Promise.thenResolve(exists =>
        if exists { Ok() } else { Error(#InitiativeNotFound) }
      )
    | None => Promise.resolve(Error(#MissingInitiativeId))
    }
  | "emergency" =>
    switch command.emergencyId {
    | Some(id) =>
      deps.emergencyExists(id)->Promise.thenResolve(exists =>
        if exists { Ok() } else { Error(#EmergencyNotFound) }
      )
    | None => Promise.resolve(Error(#MissingEmergencyId))
    }
  | "support" =>
    switch command.productId {
    | Some(id) =>
      deps.productExists(id)->Promise.thenResolve(exists =>
        if exists { Ok() } else { Error(#ProductNotFound) }
      )
    | None => Promise.resolve(Error(#MissingProductId))
    }
  | _ => Promise.resolve(Ok())
  }

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

@genType
let execute = (deps: dependencies, command: command): Promise.t<result<createdResult, error>> =>
  authorize(command)
  ->AsyncResult.fromResult
  ->AsyncResult.flatMap(cmd => validateTitle(cmd)->AsyncResult.fromResult)
  ->AsyncResult.flatMap(((cmd, validTitle)) =>
    validateContext(cmd)->AsyncResult.fromResult->AsyncResult.map(_ => validTitle)
  )
  ->AsyncResult.flatMap(validTitle => verifyExists(deps, command)->AsyncResult.map(_ => validTitle))
  ->AsyncResult.flatMap(validTitle => {
    let now = deps.now()
    let taskId = UUIDv7.value(UUIDv7.gen())
    let event: createdEvent = {
      taskId,
      organizationId: command.session.organizationId,
      title: TaskTitle.value(validTitle),
      description: command.description,
      kind: command.kind,
      initiativeId: command.initiativeId,
      productId: command.productId,
      emergencyId: command.emergencyId,
      scenarios: switch command.kind {
      | "user_story" => command.scenarios
      | _ => None
      },
      createdBy: command.session.userId,
      occurredAt: now,
    }
    deps.appendEvent(event)->Promise.thenResolve(_ =>
      Ok({taskId, title: event.title, kind: command.kind})
    )
  })
