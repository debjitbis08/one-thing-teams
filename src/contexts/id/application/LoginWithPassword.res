module D = IdDomain
module LoginDomain = Login
module Promise = RescriptCore.Promise

module Option = Belt.Option

let normalizeIdentifier = identifier => identifier->RescriptCore.String.trim

type dependencies = {
  fetchUser: string => Promise.t<option<D.registeredUser>>,
  verifyPassword: (~hash: string, ~password: string) => Promise.t<bool>,
}

type command = {
  usernameOrEmail: string,
  password: string,
}

type error = [
  | #InvalidCredentials
  | #UserNotFound
]

let execute = (deps: dependencies, cmd: command): Promise.t<result<D.userSession, error>> => {
  let identifier = normalizeIdentifier(cmd.usernameOrEmail)
  deps.fetchUser(identifier)
  ->Promise.then(userOpt =>
      switch userOpt {
      | None => Promise.resolve(Error(#UserNotFound))
      | Some(user) =>
          switch LoginDomain.passwordProvider(user) {
          | None => Promise.resolve(Error(#InvalidCredentials))
          | Some(passwordProvider) =>
              deps.verifyPassword(~hash=passwordProvider.passwordHash, ~password=cmd.password)
              ->Promise.thenResolve(isValid =>
                  if !isValid {
                    Error(#InvalidCredentials)
                  } else {
                    switch LoginDomain.sessionForPreferredOrganization(user) {
                    | None => Error(#InvalidCredentials)
                    | Some(session) => Ok(session)
                    }
                  }
                )
          }
      }
    )
}
