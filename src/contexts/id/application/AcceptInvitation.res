module Promise = RescriptCore.Promise
module Array = Belt.Array

type session = {
  sessionId: string,
  userId: string,
  organizationId: string,
  roles: array<string>,
}

@genType
type command = {
  session: session,
  token: string,
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
type acceptedEvent = {
  invitationId: string,
  organizationId: string,
  acceptedBy: string,
  expectedVersion: int,
  version: int,
  occurredAt: float,
}

@genType
type membershipAddition = {
  userId: string,
  organizationId: string,
  organizationName: string,
  role: string,
}

@genType
type acceptedResult = {
  organizationId: string,
  organizationName: string,
  role: string,
}

@genType
type dependencies = {
  now: unit => float,
  hashToken: string => string,
  findInvitationIdByTokenHash: string => Promise.t<option<string>>,
  loadAggregate: string => Promise.t<option<aggregateData>>,
  appendEvent: acceptedEvent => Promise.t<unit>,
  addMembership: membershipAddition => Promise.t<unit>,
  getUserEmail: string => Promise.t<option<string>>,
}

@genType
type error = [
  | #InvitationNotFound
  | #AlreadyAccepted
  | #AlreadyRevoked
  | #InvitationExpired
  | #EmailMismatch
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
  organizationName: string,
  email: string,
  role: string,
  tokenHash: string,
  status: string,
  expiresAt: float,
  createdBy: string,
  acceptedBy: option<string>,
}

let decodeCreatedEvent = data =>
  switch JSON.Decode.object(data) {
  | None => None
  | Some(dict) =>
    switch (
      decodeStringField(dict, "invitationId"),
      decodeStringField(dict, "organizationId"),
      decodeStringField(dict, "organizationName"),
      decodeStringField(dict, "email"),
      decodeStringField(dict, "role"),
      decodeStringField(dict, "tokenHash"),
      decodeFloatField(dict, "expiresAt"),
      decodeStringField(dict, "createdBy"),
    ) {
    | (
        Some(invitationId),
        Some(organizationId),
        Some(organizationName),
        Some(email),
        Some(role),
        Some(tokenHash),
        Some(expiresAt),
        Some(createdBy),
      ) =>
      Some({
        invitationId,
        organizationId,
        organizationName,
        email,
        role,
        tokenHash,
        status: "Pending",
        expiresAt,
        createdBy,
        acceptedBy: None,
      })
    | _ => None
    }
  }

let applyAcceptedEvent = (data, state) =>
  switch state {
  | None => None
  | Some(s) =>
    switch JSON.Decode.object(data) {
    | None => None
    | Some(dict) =>
      switch decodeStringField(dict, "acceptedBy") {
      | Some(acceptedBy) => Some({...s, status: "Accepted", acceptedBy: Some(acceptedBy)})
      | None => None
      }
    }
  }

let applyRevokedEvent = (_data, state) =>
  switch state {
  | None => None
  | Some(s) => Some({...s, status: "Revoked"})
  }

let foldEvents = events =>
  Array.reduce(events, None, (state, event: storedEvent) =>
    switch event.type_ {
    | "identity.invitation.created" => decodeCreatedEvent(event.data)
    | "identity.invitation.accepted" => applyAcceptedEvent(event.data, state)
    | "identity.invitation.revoked" => applyRevokedEvent(event.data, state)
    | _ => state
    }
  )

@genType
let execute = (deps: dependencies, command: command): Promise.t<result<acceptedResult, error>> => {
  let tokenHash = deps.hashToken(command.token)

  deps.findInvitationIdByTokenHash(tokenHash)
  ->Promise.then(idOpt =>
    switch idOpt {
    | None => Promise.resolve(Error(#InvitationNotFound))
    | Some(invitationId) =>
      deps.loadAggregate(invitationId)
      ->Promise.then(aggregateOpt =>
        switch aggregateOpt {
        | None => Promise.resolve(Error(#InvitationNotFound))
        | Some(aggregate) =>
          switch foldEvents(aggregate.events) {
          | None => Promise.resolve(Error(#InvitationNotFound))
          | Some(invitation) =>
            let now = deps.now()
            if invitation.status == "Accepted" {
              Promise.resolve(Error(#AlreadyAccepted))
            } else if invitation.status == "Revoked" {
              Promise.resolve(Error(#AlreadyRevoked))
            } else if invitation.expiresAt < now {
              Promise.resolve(Error(#InvitationExpired))
            } else {
              deps.getUserEmail(command.session.userId)
              ->Promise.then(emailOpt =>
                switch emailOpt {
                | None => Promise.resolve(Error(#InvitationNotFound))
                | Some(userEmail) =>
                  if String.toLowerCase(userEmail) != String.toLowerCase(invitation.email) {
                    Promise.resolve(Error(#EmailMismatch))
                  } else {
                    let event: acceptedEvent = {
                      invitationId: invitation.invitationId,
                      organizationId: invitation.organizationId,
                      acceptedBy: command.session.userId,
                      expectedVersion: aggregate.version,
                      version: aggregate.version + 1,
                      occurredAt: now,
                    }
                    deps.appendEvent(event)
                    ->Promise.then(_ => {
                      let membership: membershipAddition = {
                        userId: command.session.userId,
                        organizationId: invitation.organizationId,
                        organizationName: invitation.organizationName,
                        role: invitation.role,
                      }
                      deps.addMembership(membership)
                    })
                    ->Promise.thenResolve(_ =>
                      Ok({
                        organizationId: invitation.organizationId,
                        organizationName: invitation.organizationName,
                        role: invitation.role,
                      })
                    )
                  }
                }
              )
            }
          }
        }
      )
    }
  )
}
