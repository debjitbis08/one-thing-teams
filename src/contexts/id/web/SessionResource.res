module JSON = RescriptCore.JSON
module Dict = RescriptCore.Dict
module String = RescriptCore.String
module Array = Belt.Array

module D = IdDomain
module LoginWithPassword = LoginWithPassword

type loginRequest = {
  usernameOrEmail: string,
  password: string,
}

let sanitizeLoginRequest = (req: loginRequest): loginRequest => {
  {
    usernameOrEmail: req.usernameOrEmail->String.trim,
    password: req.password,
  }
}

let encodeUserSession = (session: D.userSession): JSON.t => {
  let dict = Dict.make()
  let UserId.UserId(userUuid) = session.userId
  let OrganizationId.OrganizationId(orgUuid) = Organization.id(session.organization)
  dict->Dict.set("userId", JSON.Encode.string(UUIDv7.value(userUuid)))
  dict->Dict.set("username", JSON.Encode.string(session.username))
  dict->Dict.set("displayName", JSON.Encode.string(session.displayName))
  dict->Dict.set("organizationId", JSON.Encode.string(UUIDv7.value(orgUuid)))
  dict->Dict.set("organizationName", JSON.Encode.string(Organization.nameValue(session.organization)))
  dict->Dict.set(
    "roles",
    session.roles
    ->Array.map(role => JSON.Encode.string(role))
    ->JSON.Encode.array
  )
  JSON.Encode.object(dict)
}

let encodeError = (message: string): JSON.t => {
  let dict = Dict.make()
  dict->Dict.set("error", JSON.Encode.string(message))
  JSON.Encode.object(dict)
}

let commandOfLoginRequest = (req: loginRequest): LoginWithPassword.command => {
  {
    usernameOrEmail: req.usernameOrEmail,
    password: req.password,
  }
}
