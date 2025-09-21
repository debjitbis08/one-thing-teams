module Dict = RescriptCore.Dict
module JSON = RescriptCore.JSON

type request = {
  name: string,
  ownerId: string,
}

let encodeOrganization = (organization: Organization.t): JSON.t => {
  let OrganizationId.OrganizationId(uuid) = Organization.id(organization)
  let UserId.UserId(ownerUuid) = Organization.owner(organization)
  let dict = Dict.make()
  dict->Dict.set("id", JSON.Encode.string(UUIDv7.value(uuid)))
  dict->Dict.set("name", JSON.Encode.string(Organization.nameValue(organization)))
  dict->Dict.set("shortCode", JSON.Encode.string(Organization.shortCodeValue(organization)))
  dict->Dict.set("ownerId", JSON.Encode.string(UUIDv7.value(ownerUuid)))
  JSON.Encode.object(dict)
}

let encodeError = (message: string): JSON.t => {
  let dict = Dict.make()
  dict->Dict.set("error", JSON.Encode.string(message))
  JSON.Encode.object(dict)
}