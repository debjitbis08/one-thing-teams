module Promise = RescriptCore.Promise
module Array = Belt.Array

let hasAllowedRole = roles => roles->Array.some(role => role == "OWNER" || role == "ADMIN")

type session = {
  sessionId: string,
  userId: string,
  organizationId: string,
  roles: array<string>,
}

@genType
type command = {
  session: session,
  initiativeId: string,
  progressStatus: string,
}

@genType
type progressStatusUpdatedEvent = {
  initiativeId: string,
  organizationId: string,
  progressStatus: string,
  updatedBy: string,
  sessionId: string,
  expectedVersion: int,
  version: int,
  occurredAt: float,
}

@genType
type initiativeInfo = {
  version: int,
  exists: bool,
}

@genType
type dependencies = {
  now: unit => float,
  loadInitiative: string => Promise.t<option<initiativeInfo>>,
  appendEvent: progressStatusUpdatedEvent => Promise.t<unit>,
}

@genType
type error = [
  | #Forbidden
  | #InitiativeNotFound
  | #InvalidProgressStatus(string)
]

let validStatuses = [
  "thinking",
  "trying",
  "building",
  "finishing",
  "deploying",
  "distributing",
  "stuck",
]

let validateStatus = (status: string) =>
  if validStatuses->Array.some(s => s == status) {
    Ok(status)
  } else {
    Error(#InvalidProgressStatus(status))
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
  ->AsyncResult.flatMap(_ => validateStatus(command.progressStatus)->AsyncResult.fromResult)
  ->AsyncResult.flatMap(_ =>
    deps.loadInitiative(command.initiativeId)
    ->Promise.thenResolve(opt =>
      switch opt {
      | None => Error(#InitiativeNotFound)
      | Some(info) => Ok(info)
      }
    )
  )
  ->AsyncResult.flatMap(info => {
    let event: progressStatusUpdatedEvent = {
      initiativeId: command.initiativeId,
      organizationId: command.session.organizationId,
      progressStatus: command.progressStatus,
      updatedBy: command.session.userId,
      sessionId: command.session.sessionId,
      expectedVersion: info.version,
      version: info.version + 1,
      occurredAt: deps.now(),
    }
    deps.appendEvent(event)->Promise.thenResolve(_ => Ok())
  })
