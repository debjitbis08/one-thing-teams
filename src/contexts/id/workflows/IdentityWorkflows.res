module Promise = RescriptCore.Promise

module Login = {
  module Impl = LoginWithPassword.Make({
    let fetchUser = _identifier => Promise.resolve(None)
    let verifyPassword = (~hash, ~password) => PasswordHasher.verify(~hash, ~password)
  })

  let execute = Impl.execute
}
