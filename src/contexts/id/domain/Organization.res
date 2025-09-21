module Name = ConstrainedString.Make({
  let minLength = 1
  let maxLength = None
  let label = "Organization name"
})

type error = [#InvalidName(string) | #InvalidShortCode(string)]

type t = {
  organizationId: OrganizationId.organizationId,
  name: Name.t,
  shortCode: ShortCode.t,
  owner: UserId.userId,
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
