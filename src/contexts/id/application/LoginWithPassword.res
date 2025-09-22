type dependencies = {
  verifyPassword: (~hash: string, ~password: string) => bool,
  fetchUser: string => option<IdDomain.registeredUser>,
}

type command = {
  usernameOrEmail: string,
  password: string,
}

type error = [
  | #InvalidCredentials
  | #UserNotFound
]

let execute = (_deps: dependencies, _cmd: command): result<IdDomain.userSession, error> => {
  Error(#InvalidCredentials)
}
