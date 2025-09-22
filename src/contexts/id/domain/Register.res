module D = IdDomain
module String = RescriptCore.String
module Date = RescriptCore.Date

let passwordLengthIsValid = password => String.length(password) >= 8

type preparedRegistration = {
  email: Email.t,
  username: string,
  displayName: option<string>,
  initialOrganizationName: string,
  rawPassword: string,
}

let preparePasswordRegistration = (
  registration: D.passwordRegistration,
): result<preparedRegistration, D.passwordRegistrationError> => {
  let password = registration.password

  if !passwordLengthIsValid(password) {
    Error(#PasswordTooShort)
  } else {
    switch registration.confirmPassword {
    | Some(confirm) if confirm != password => Error(#PasswordsDoNotMatch)
    | _ =>
      Ok({
        email: registration.email,
        username: registration.username,
        displayName: registration.displayName,
        initialOrganizationName: registration.initialOrganizationName,
        rawPassword: password,
      })
    }
  }
}

let registerPreparedUser = (
  ~passwordHash: string,
  prepared: preparedRegistration,
): result<D.registeredUser, D.passwordRegistrationError> => {
  let displayName =
    switch prepared.displayName {
    | Some(name) => name
    | None => prepared.email->Email.value
    }

  let userId = UserId.UserId(UUIDv7.gen())

  let user: D.user = {
    userId,
    email: prepared.email,
    username: prepared.username,
    displayName,
    status: D.ACTIVE,
  }

  switch Organization.create(~name=prepared.initialOrganizationName, ~owner=userId, ()) {
  | Error(orgError) => Error((orgError :> D.passwordRegistrationError))
  | Ok(defaultOrganization) =>
    let provider: D.authProvider =
      D.PasswordProvider({
        providerAssignedId: {
          let UserId.UserId(uuid) = userId
          UUIDv7.value(uuid)
        },
        passwordHash,
      })

    let membership: D.membership = {
      organization: defaultOrganization,
      role: D.OWNER,
    }

    let timestamp = Date.now()

    Ok({
      user,
      authProviders: list{provider},
      defaultOrganization,
      preferredOrganization: defaultOrganization,
      memberships: list{membership},
      isContributor: false,
      createdAt: timestamp,
      updatedAt: timestamp,
    })
  }
}
