type request = {
  name: string,
  ownerId: string,
}

type parseError = string

let decodeStringField = (dict: RescriptCore.Dict.t<RescriptCore.JSON.t>, key: string): option<string> =>
  switch RescriptCore.Dict.get(dict, key) {
  | Some(value) => RescriptCore.JSON.Decode.string(value)
  | None => None
  }

let parseRequest = (json: RescriptCore.JSON.t): result<request, parseError> =>
  switch RescriptCore.JSON.Decode.object(json) {
  | Some(dict) =>
      let maybeName = decodeStringField(dict, "name")
      let maybeOwner = decodeStringField(dict, "ownerId")
      switch (maybeName, maybeOwner) {
      | (Some(name), Some(ownerId)) =>
          let trimmed = name->RescriptCore.String.trim
          if trimmed == "" {
            Error("Organization name is required")
          } else {
            Ok({name: trimmed, ownerId})
          }
      | (None, _) => Error("Field 'name' must be a string")
      | (_, None) => Error("Field 'ownerId' must be a string")
      }
  | None => Error("Request body must be a JSON object")
  }

let commandOfRequest = ({name, ownerId}: request): CreateOrganization.command => {
  name,
  ownerId,
}

let encodeOrganization = (organization: Organization.t): RescriptCore.JSON.t => {
  let OrganizationId.OrganizationId(uuid) = Organization.id(organization)
  let UserId.UserId(ownerUuid) = Organization.owner(organization)
  let dict = RescriptCore.Dict.empty()
  dict->RescriptCore.Dict.set("id", RescriptCore.JSON.Encode.string(UUIDv7.value(uuid)))
  dict->RescriptCore.Dict.set("name", RescriptCore.JSON.Encode.string(Organization.nameValue(organization)))
  dict->RescriptCore.Dict.set("shortCode", RescriptCore.JSON.Encode.string(Organization.shortCodeValue(organization)))
  dict->RescriptCore.Dict.set("ownerId", RescriptCore.JSON.Encode.string(UUIDv7.value(ownerUuid)))
  RescriptCore.JSON.Encode.object(dict)
}

let encodeError = (message: string): RescriptCore.JSON.t => {
  let dict = RescriptCore.Dict.empty()
  dict->RescriptCore.Dict.set("error", RescriptCore.JSON.Encode.string(message))
  RescriptCore.JSON.Encode.object(dict)
}

let errorMessage = (err: CreateOrganization.error): string =>
  CreateOrganization.errorMessage(err)

@genType
type requestJs = request

@genType
type parseErrorJs = parseError

@genType
let parseRequestJs = parseRequest

@genType
let commandOfRequestJs = commandOfRequest

@genType
let encodeOrganizationJs = encodeOrganization

@genType
let encodeErrorJs = encodeError

@genType
let errorMessageJs = errorMessage
