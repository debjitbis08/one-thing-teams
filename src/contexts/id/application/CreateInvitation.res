module Promise = RescriptCore.Promise
module Array = Belt.Array

let hasAllowedRole = roles => roles->Array.some(role => role == "OWNER" || role == "ADMIN")

let invitableRoles = ["ADMIN", "EDITOR", "VIEWER", "GUEST"]

let isInvitableRole = role => invitableRoles->Array.some(r => r == role)

type session = {
  sessionId: string,
  userId: string,
  organizationId: string,
  roles: array<string>,
}

@genType
type command = {
  session: session,
  email: string,
  role: string,
}

@genType
type createdEvent = {
  invitationId: string,
  organizationId: string,
  organizationName: string,
  email: string,
  role: string,
  tokenHash: string,
  createdBy: string,
  expiresAt: float,
  occurredAt: float,
}

@genType
type createdResult = {
  invitationId: string,
  token: string,
  expiresAt: float,
}

@genType
type dependencies = {
  now: unit => float,
  generateToken: unit => string,
  hashToken: string => string,
  appendEvent: createdEvent => Promise.t<unit>,
  organizationName: string => Promise.t<option<string>>,
}

@genType
type error = [
  | #Forbidden
  | #InvalidEmail(string)
  | #InvalidRole
  | #OrganizationNotFound
]

@genType
let execute = (deps: dependencies, command: command): Promise.t<result<createdResult, error>> => {
  if !hasAllowedRole(command.session.roles) {
    Promise.resolve(Error(#Forbidden))
  } else if !isInvitableRole(command.role) {
    Promise.resolve(Error(#InvalidRole))
  } else {
    switch Email.make(command.email) {
    | Error(#InvalidEmail(original)) => Promise.resolve(Error(#InvalidEmail(original)))
    | Ok(_email) =>
      let organizationId = command.session.organizationId
      deps.organizationName(organizationId)
      ->Promise.then(orgNameOpt =>
        switch orgNameOpt {
        | None => Promise.resolve(Error(#OrganizationNotFound))
        | Some(orgName) =>
          let now = deps.now()
          let invitationId = UUIDv7.value(UUIDv7.gen())
          let token = deps.generateToken()
          let tokenHash = deps.hashToken(token)
          let expiresAt = now +. Invitation.defaultExpirationMs

          let event: createdEvent = {
            invitationId,
            organizationId,
            organizationName: orgName,
            email: Email.value(_email),
            role: command.role,
            tokenHash,
            createdBy: command.session.userId,
            expiresAt,
            occurredAt: now,
          }

          deps.appendEvent(event)
          ->Promise.thenResolve(_ =>
            Ok({
              invitationId,
              token,
              expiresAt,
            })
          )
        }
      )
    }
  }
}
