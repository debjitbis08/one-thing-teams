module JSON = RescriptCore.JSON
module Dict = RescriptCore.Dict
module String = RescriptCore.String

module D = IdDomain
module RegisterWithPasswordApp = RegisterWithPassword

type registrationRequest = {
  email: string,
  username: string,
  displayName: option<string>,
  password: string,
  confirmPassword: option<string>,
  initialOrganizationName: string,
}

let sanitizeRegistrationRequest = (req: registrationRequest): registrationRequest => {
  let trimmedName = req.initialOrganizationName->String.trim
  let normalizedDisplayName =
    switch req.displayName {
    | Some(name) =>
        let trimmed = name->String.trim
        if trimmed == "" {
          None
        } else {
          Some(trimmed)
        }
    | None => None
    }
  {
    email: req.email->String.trim,
    username: req.username->String.trim,
    displayName: normalizedDisplayName,
    password: req.password,
    confirmPassword: req.confirmPassword,
    initialOrganizationName: trimmedName,
  }
}

let encodeRegisteredUser = (user: D.registeredUser): JSON.t => {
  let dict = Dict.make()
  let {user: identity, defaultOrganization} = user
  let {userId, username, displayName, email} = identity
  let UserId.UserId(uuid) = userId
  let OrganizationId.OrganizationId(orgUuid) = Organization.id(defaultOrganization)
  dict->Dict.set("userId", JSON.Encode.string(UUIDv7.value(uuid)))
  dict->Dict.set("username", JSON.Encode.string(username))
  dict->Dict.set("displayName", JSON.Encode.string(displayName))
  dict->Dict.set("email", JSON.Encode.string(Email.value(email)))
  dict->Dict.set("organizationId", JSON.Encode.string(UUIDv7.value(orgUuid)))
  dict->Dict.set("organizationName", JSON.Encode.string(Organization.nameValue(defaultOrganization)))
  JSON.Encode.object(dict)
}

let encodeError = (message: string): JSON.t => {
  let dict = Dict.make()
  dict->Dict.set("error", JSON.Encode.string(message))
  JSON.Encode.object(dict)
}

let commandOfRegistrationRequest = (req: registrationRequest): RegisterWithPasswordApp.command => {
  {
    email: req.email,
    username: req.username,
    displayName: req.displayName,
    password: req.password,
    confirmPassword: req.confirmPassword,
    initialOrganizationName: req.initialOrganizationName,
  }
}
