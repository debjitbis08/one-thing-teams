module D = IdDomain
module RegisterDomain = Register
module Promise = RescriptCore.Promise
module List = Belt.List
module Array = Belt.Array

@genType
type registrationUserInfo = {
  userId: string,
  email: string,
  username: string,
  displayName: string,
}

@genType
type registrationOrganizationInfo = {
  organizationId: string,
  name: string,
  shortCode: string,
}

@genType
type registrationMembershipInfo = {
  organizationId: string,
  role: string,
}

@genType
type registrationEvent = {
  aggregateId: string,
  orgId: string,
  version: int,
  occurredAt: float,
  isContributor: bool,
  user: registrationUserInfo,
  defaultOrganization: registrationOrganizationInfo,
  memberships: array<registrationMembershipInfo>,
}

@genType
type dependencies = {
  hashPassword: string => Promise.t<string>,
  storeEvents: registrationEvent => Promise.t<unit>,
  storeSnapshot: (registrationEvent, D.registeredUser) => Promise.t<unit>,
}

@genType
type command = {
  email: string,
  username: string,
  displayName: option<string>,
  password: string,
  confirmPassword: option<string>,
  initialOrganizationName: string,
}

@genType
type error = [
  | #InvalidEmail(Email.error)
  | D.passwordRegistrationError
]

let memberRoleToString = role =>
  switch role {
  | D.OWNER => "OWNER"
  | D.ADMIN => "ADMIN"
  | D.EDITOR => "EDITOR"
  | D.VIEWER => "VIEWER"
  | D.GUEST => "GUEST"
  }

let uuidToString = uuid => UUIDv7.value(uuid)

let userIdToString = userId => {
  let UserId.UserId(uuid) = userId
  uuidToString(uuid)
}

let organizationIdToString = organization => {
  let OrganizationId.OrganizationId(uuid) = Organization.id(organization)
  uuidToString(uuid)
}

let makeRegistrationEvent = (registeredUser: D.registeredUser): registrationEvent => {
  let aggregateId = registeredUser.user.userId->userIdToString
  let defaultOrganization = registeredUser.defaultOrganization
  let orgId = defaultOrganization->organizationIdToString
  let memberships =
    registeredUser.memberships
    ->List.toArray
    ->Array.map(membership => {
        let organizationId = membership.organization->organizationIdToString
        {organizationId, role: membership.role->memberRoleToString}
      })

  {
    aggregateId,
    orgId,
    version: 1,
    occurredAt: registeredUser.createdAt,
    isContributor: registeredUser.isContributor,
    user: {
      userId: aggregateId,
      email: registeredUser.user.email->Email.value,
      username: registeredUser.user.username,
      displayName: registeredUser.user.displayName,
    },
    defaultOrganization: {
      organizationId: orgId,
      name: Organization.nameValue(defaultOrganization),
      shortCode: Organization.shortCodeValue(defaultOrganization),
    },
    memberships,
  }
}

@genType
let execute = (deps: dependencies, cmd: command): Promise.t<result<D.registeredUser, error>> =>
  switch Email.make(cmd.email) {
  | Error(emailError) => Promise.resolve(Error(#InvalidEmail(emailError)))
  | Ok(email) =>
    let registration: D.passwordRegistration = {
      email,
      username: cmd.username,
      displayName: cmd.displayName,
      password: cmd.password,
      confirmPassword: cmd.confirmPassword,
      initialOrganizationName: cmd.initialOrganizationName,
    }

    switch RegisterDomain.preparePasswordRegistration(registration) {
    | Error(domainError) => Promise.resolve(Error((domainError :> error)))
    | Ok(prepared) =>
        PasswordStrength.verifyStrong(prepared.rawPassword)
        ->Promise.then(strong =>
            if !strong {
              Promise.resolve(Error((#PasswordCompromised :> error)))
            } else {
              prepared.rawPassword
              ->deps.hashPassword
              ->Promise.then(passwordHash =>
                  switch RegisterDomain.registerPreparedUser(~passwordHash, prepared) {
                  | Ok(registeredUser) =>
                      let event = makeRegistrationEvent(registeredUser)
                      deps.storeEvents(event)
                      ->Promise.then(() => deps.storeSnapshot(event, registeredUser))
                      ->Promise.thenResolve(_ => Ok(registeredUser))
                  | Error(domainError) => Promise.resolve(Error((domainError :> error)))
                  }
                )
            }
          )
    }
  }
