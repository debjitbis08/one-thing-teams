type command = {
  name: string,
  ownerId: string,
}

type error = [Organization.error | #InvalidOwner(string)]

let execute = ({name, ownerId}: command): result<Organization.t, error> =>
  switch UUIDv7.ofString(ownerId) {
  | Ok(uuid) =>
      let owner = UserId.UserId(uuid)
      switch Organization.create(~name, ~owner, ()) {
      | Ok(org) => Ok(org)
      | Error(e) => Error((e :> error))
      }
  | Error(#InvalidUuid(original)) => Error(#InvalidOwner(original))
  | Error(#NotV7(original)) => Error(#InvalidOwner(original))
  }

let errorMessage = (err: error): string =>
  switch err {
  | #InvalidOwner(original) => "Invalid owner identifier: " ++ original
  | #InvalidName(original) => "Organization name is invalid: " ++ original
  | #InvalidShortCode(original) => "Unable to derive shortcode from name: " ++ original
  }

@genType
type commandJs = command

@genType
type errorJs = error

@genType
let executeJs = execute

@genType
let errorMessageJs = errorMessage
