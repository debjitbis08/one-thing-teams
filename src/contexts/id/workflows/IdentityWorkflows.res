module Promise = RescriptCore.Promise
module D = IdDomain

@module("../infrastructure/UserSnapshotRepository")
external fetchRegisteredUserByIdentifier: string => Promise.t<option<D.registeredUser>> = "fetchRegisteredUserByIdentifier"

module Login = {
  module Impl = LoginWithPassword.Make({
    let fetchUser = identifier => fetchRegisteredUserByIdentifier(identifier)
    let verifyPassword = (~hash, ~password) => PasswordHasher.verify(~hash, ~password)
  })

  let execute = Impl.execute
}
