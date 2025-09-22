module D = IdDomain
module RegisterDomain = Register
module Promise = RescriptCore.Promise

type dependencies = {
  hashPassword: string => Promise.t<string>,
}

type command = {
  email: string,
  username: string,
  displayName: option<string>,
  password: string,
  confirmPassword: option<string>,
  initialOrganizationName: string,
}

type error = [
  | #InvalidEmail(Email.error)
  | D.passwordRegistrationError
]

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
        prepared.rawPassword
        ->deps.hashPassword
        ->Promise.thenResolve(passwordHash =>
            switch RegisterDomain.registerPreparedUser(~passwordHash, prepared) {
            | Ok(registeredUser) => Ok(registeredUser)
            | Error(domainError) => Error((domainError :> error))
            }
          )
    }
  }
