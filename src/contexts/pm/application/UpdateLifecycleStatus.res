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
  lifecycleStatus: string,
  doneEvidence: option<string>,
  outcomeNotes: option<string>,
}

@genType
type lifecycleStatusUpdatedEvent = {
  initiativeId: string,
  organizationId: string,
  lifecycleStatus: string,
  doneEvidence: option<string>,
  outcomeNotes: option<string>,
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
  appendEvent: lifecycleStatusUpdatedEvent => Promise.t<unit>,
}

@genType
type error = [
  | #Forbidden
  | #InitiativeNotFound
  | #InvalidLifecycleStatus(string)
]

let validStatuses = ["waiting", "active", "done", "abandoned"]

let validateStatus = (status: string) =>
  if validStatuses->Array.some(s => s == status) {
    Ok(status)
  } else {
    Error(#InvalidLifecycleStatus(status))
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
  ->AsyncResult.flatMap(_ => validateStatus(command.lifecycleStatus)->AsyncResult.fromResult)
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
    let event: lifecycleStatusUpdatedEvent = {
      initiativeId: command.initiativeId,
      organizationId: command.session.organizationId,
      lifecycleStatus: command.lifecycleStatus,
      doneEvidence: switch command.lifecycleStatus {
      | "done" => command.doneEvidence
      | _ => None
      },
      outcomeNotes: switch command.lifecycleStatus {
      | "done" | "abandoned" => command.outcomeNotes
      | _ => None
      },
      updatedBy: command.session.userId,
      sessionId: command.session.sessionId,
      expectedVersion: info.version,
      version: info.version + 1,
      occurredAt: deps.now(),
    }
    deps.appendEvent(event)->Promise.thenResolve(_ => Ok())
  })
