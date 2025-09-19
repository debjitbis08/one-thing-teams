open GlobalUniqueId

@genType
 type organizationId = GlobalUniqueId.t

@genType
 type organization = {
  id: organizationId,
  name: string,
  shortCode: string,
}

@genType
let makeId = (~id=?, ()) => GlobalUniqueId.make(~id?, ())

@genType
let make = (~id=?, ~name, ~shortCode, ()) => {
  id: makeId(~id?, ()),
  name,
  shortCode,
}

@genType
let rename = (~organization, ~name) => {...organization, name}

@genType
let changeShortCode = (~organization, ~shortCode) => {...organization, shortCode}

@genType
let equals = (left, right) => GlobalUniqueId.equal(left.id, right.id)
