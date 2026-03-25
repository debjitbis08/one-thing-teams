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
type evidenceItem = {
  kind: string,
  url: option<string>,
  description: option<string>,
  signedOffBy: option<string>,
  reason: option<string>,
}

@genType
type command = {
  session: session,
  initiativeId: string,
  lifecycleStatus: string,
  evidence: option<array<evidenceItem>>,
  outcomeNotes: option<string>,
}

@genType
type lifecycleStatusUpdatedEvent = {
  initiativeId: string,
  organizationId: string,
  lifecycleStatus: string,
  evidence: array<evidenceItem>,
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
  | #DoneEvidenceRequired
  | #InvalidEvidence(string)
]

let validStatuses = ["waiting", "active", "done", "abandoned"]

let validEvidenceKinds = ["live_url", "tracking_event", "screenshot", "manual_sign_off"]

let validateStatus = (status: string) =>
  if validStatuses->Array.some(s => s == status) {
    Ok(status)
  } else {
    Error(#InvalidLifecycleStatus(status))
  }

let validateEvidenceItem = (item: evidenceItem): result<unit, error> =>
  if !(validEvidenceKinds->Array.some(k => k == item.kind)) {
    Error(
      #InvalidEvidence(
        "Unknown evidence kind: '" ++
        item.kind ++
        "'. Must be 'live_url', 'tracking_event', 'screenshot', or 'manual_sign_off'",
      ),
    )
  } else {
    switch item.kind {
    | "live_url" =>
      switch item.url {
      | Some(u) if String.trim(u) != "" => Ok()
      | _ => Error(#InvalidEvidence("'live_url' evidence requires a 'url' field"))
      }
    | "tracking_event" =>
      switch item.description {
      | Some(d) if String.trim(d) != "" => Ok()
      | _ => Error(#InvalidEvidence("'tracking_event' evidence requires a 'description' field"))
      }
    | "screenshot" =>
      switch item.url {
      | Some(u) if String.trim(u) != "" => Ok()
      | _ => Error(#InvalidEvidence("'screenshot' evidence requires a 'url' field"))
      }
    | "manual_sign_off" =>
      switch (item.signedOffBy, item.reason) {
      | (Some(s), Some(r)) if String.trim(s) != "" && String.trim(r) != "" => Ok()
      | _ =>
        Error(
          #InvalidEvidence("'manual_sign_off' evidence requires 'signedOffBy' and 'reason' fields"),
        )
      }
    | _ => Ok()
    }
  }

let validateEvidence = (status: string, evidence: array<evidenceItem>): result<unit, error> =>
  switch status {
  | "done" =>
    if Array.length(evidence) == 0 {
      Error(#DoneEvidenceRequired)
    } else {
      evidence->Array.reduce(Ok(), (acc, item) =>
        switch acc {
        | Error(_) => acc
        | Ok() => validateEvidenceItem(item)
        }
      )
    }
  | _ => Ok()
  }

let authorize = (command: command) =>
  if hasAllowedRole(command.session.roles) {
    Ok(command)
  } else {
    Error(#Forbidden)
  }

@genType
let execute = (deps: dependencies, command: command): Promise.t<result<unit, error>> => {
  let evidence = switch command.evidence {
  | Some(items) => items
  | None => []
  }

  authorize(command)
  ->AsyncResult.fromResult
  ->AsyncResult.flatMap(_ => validateStatus(command.lifecycleStatus)->AsyncResult.fromResult)
  ->AsyncResult.flatMap(_ => validateEvidence(command.lifecycleStatus, evidence)->AsyncResult.fromResult)
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
      evidence: switch command.lifecycleStatus {
      | "done" => evidence
      | _ => []
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
}
