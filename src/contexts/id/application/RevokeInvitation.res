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
  invitationId: string,
}

@genType
type storedEvent = {
  version: int,
  type_: string,
  data: JSON.t,
}

@genType
type aggregateData = {
  version: int,
  events: array<storedEvent>,
}

@genType
type revokedEvent = {
  invitationId: string,
  organizationId: string,
  revokedBy: string,
  expectedVersion: int,
  version: int,
  occurredAt: float,
}

@genType
type dependencies = {
  now: unit => float,
  loadAggregate: string => Promise.t<option<aggregateData>>,
  appendEvent: revokedEvent => Promise.t<unit>,
}

@genType
type error = [
  | #Forbidden
  | #InvitationNotFound
  | #AlreadyAccepted
  | #AlreadyRevoked
  | #InvitationExpired
]

let decodeStringField = (dict, key) =>
  switch Dict.get(dict, key) {
  | Some(value) => JSON.Decode.string(value)
  | None => None
  }

let decodeFloatField = (dict, key) =>
  switch Dict.get(dict, key) {
  | Some(value) => JSON.Decode.float(value)
  | None => None
  }

type invitationState = {
  invitationId: string,
  organizationId: string,
  status: string,
  expiresAt: float,
}

let foldEvents = events =>
  Array.reduce(events, None, (state, event: storedEvent) =>
    switch event.type_ {
    | "identity.invitation.created" =>
      switch JSON.Decode.object(event.data) {
      | None => None
      | Some(dict) =>
        switch (
          decodeStringField(dict, "invitationId"),
          decodeStringField(dict, "organizationId"),
          decodeFloatField(dict, "expiresAt"),
        ) {
        | (Some(invitationId), Some(organizationId), Some(expiresAt)) =>
          Some({invitationId, organizationId, status: "Pending", expiresAt})
        | _ => None
        }
      }
    | "identity.invitation.accepted" =>
      switch state {
      | None => None
      | Some(s) => Some({...s, status: "Accepted"})
      }
    | "identity.invitation.revoked" =>
      switch state {
      | None => None
      | Some(s) => Some({...s, status: "Revoked"})
      }
    | _ => state
    }
  )

@genType
let execute = (deps: dependencies, command: command): Promise.t<result<unit, error>> => {
  if !hasAllowedRole(command.session.roles) {
    Promise.resolve(Error(#Forbidden))
  } else {
    deps.loadAggregate(command.invitationId)
    ->Promise.then(aggregateOpt =>
      switch aggregateOpt {
      | None => Promise.resolve(Error(#InvitationNotFound))
      | Some(aggregate) =>
        switch foldEvents(aggregate.events) {
        | None => Promise.resolve(Error(#InvitationNotFound))
        | Some(invitation) =>
          if invitation.organizationId != command.session.organizationId {
            Promise.resolve(Error(#Forbidden))
          } else {
            let now = deps.now()
            if invitation.status == "Accepted" {
              Promise.resolve(Error(#AlreadyAccepted))
            } else if invitation.status == "Revoked" {
              Promise.resolve(Error(#AlreadyRevoked))
            } else if invitation.expiresAt < now {
              Promise.resolve(Error(#InvitationExpired))
            } else {
              let event: revokedEvent = {
                invitationId: invitation.invitationId,
                organizationId: invitation.organizationId,
                revokedBy: command.session.userId,
                expectedVersion: aggregate.version,
                version: aggregate.version + 1,
                occurredAt: now,
              }
              deps.appendEvent(event)
              ->Promise.thenResolve(_ => Ok(()))
            }
          }
        }
      }
    )
  }
}
