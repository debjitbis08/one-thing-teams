module Name = ConstrainedString.Make({
  let minLength = 1
  let maxLength = Some(50)
  let label = "Organization name"
})

type error = [#InvalidName(string) | #InvalidShortCode(string)]

type t = {
  organizationId: OrganizationId.organizationId,
  name: Name.t,
  shortCode: ShortCode.t,
  owner: UserId.userId,
}

type renameEvent = {
  name: Name.t,
  shortCode: ShortCode.t,
}

type renameEventStrings = {
  name: string,
  shortCode: string,
}

@genType
let create = (~name: string, ~owner: UserId.userId, ~id: option<string>=?, ()): result<t, error> => {
  let trimmed = name->Js.String2.trim

  switch Name.make(trimmed) {
  | Belt.Result.Error(#InvalidString(original)) =>
      Belt.Result.Error(#InvalidName(original))
  | Belt.Result.Ok(validName) =>
      switch ShortCode.make(trimmed) {
      | Belt.Result.Ok(shortCode) =>
          Belt.Result.Ok({
            organizationId:
              switch id {
              | Some(value) => OrganizationId.OrganizationId(UUIDv7.ofStringUnsafe(value))
              | None => OrganizationId.OrganizationId(UUIDv7.gen())
              },
            name: validName,
            shortCode,
            owner,
          })
      | Belt.Result.Error(#InvalidShortCode(original)) =>
          Belt.Result.Error(#InvalidShortCode(original))
      }
  }
}

@genType
let transferOwnership = (~organization, ~newOwner: UserId.userId, ()) =>
  {...organization, owner: newOwner}

@genType
let id = (organization: t) => organization.organizationId

@genType
let owner = (organization: t) => organization.owner

@genType
let nameValue = (organization: t) => organization.name->Name.value

@genType
let shortCodeValue = (organization: t) => organization.shortCode->ShortCode.value

let rename = (~organization: t, ~name: string): result<renameEvent, error> => {
  let _unused = organization;
  let trimmed = name->Js.String2.trim

  switch Name.make(trimmed) {
  | Belt.Result.Error(#InvalidString(original)) => Belt.Result.Error(#InvalidName(original))
  | Belt.Result.Ok(validName) =>
      switch ShortCode.make(trimmed) {
      | Belt.Result.Ok(shortCode) => Belt.Result.Ok({name: validName, shortCode})
      | Belt.Result.Error(#InvalidShortCode(original)) => Belt.Result.Error(#InvalidShortCode(original))
      }
  }
}

let applyRenameEvent = (~organization, event: renameEvent): t => {
  {
    organizationId: organization.organizationId,
    name: event.name,
    shortCode: event.shortCode,
    owner: organization.owner,
  }
}

@genType
let renameEventToStrings = ({name, shortCode}: renameEvent): renameEventStrings => {
  name: Name.value(name),
  shortCode: ShortCode.value(shortCode),
}

@genType
let renameEventOfStrings = (~name, ~shortCode): option<renameEvent> =>
  switch (Name.make(name), ShortCode.make(shortCode)) {
  | (Belt.Result.Ok(validName), Belt.Result.Ok(validShortCode)) => Some({name: validName, shortCode: validShortCode})
  | _ => None
  }
