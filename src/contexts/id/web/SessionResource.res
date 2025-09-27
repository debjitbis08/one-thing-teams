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

type sessionTokenInput = {
  userId: string,
  organizationId: string,
  roles: array<string>,
}

type issuedTokens = {
  sessionToken: string,
  sessionTokenExpiresAt: string,
  sessionJwt: string,
  sessionJwtExpiresAt: string,
}

let sessionTokenInputOfUserSession = (session: D.userSession): sessionTokenInput => {
  let UserId.UserId(userUuid) = session.userId
  let OrganizationId.OrganizationId(orgUuid) = Organization.id(session.organization)
  {
    userId: UUIDv7.value(userUuid),
    organizationId: UUIDv7.value(orgUuid),
    roles: session.roles,
  }
}

let encodeLoginSuccess = (~session: D.userSession, ~tokens: issuedTokens): JSON.t => {
  let dict = Dict.make()
  dict->Dict.set("user", encodeUserSession(session))
  let tokensDict = Dict.make()
  tokensDict->Dict.set("sessionToken", JSON.Encode.string(tokens.sessionToken))
  tokensDict->Dict.set("sessionTokenExpiresAt", JSON.Encode.string(tokens.sessionTokenExpiresAt))
  tokensDict->Dict.set("sessionJwt", JSON.Encode.string(tokens.sessionJwt))
  tokensDict->Dict.set("sessionJwtExpiresAt", JSON.Encode.string(tokens.sessionJwtExpiresAt))
  dict->Dict.set("tokens", JSON.Encode.object(tokensDict))
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
