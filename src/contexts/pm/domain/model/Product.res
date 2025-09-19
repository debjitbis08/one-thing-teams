open GlobalUniqueId
open Organization

@genType
 type productId = GlobalUniqueId.t

@genType
 type product = {
  id: productId,
  orgId: organizationId,
  name: string,
  shortCode: string,
  description: option<string>,
}

@genType
let makeId = (~id=?, ()) => GlobalUniqueId.make(~id?, ())

@genType
let make = (~orgId, ~name, ~shortCode, ~description=?, ~id=?, ()) => {
  id: makeId(~id?, ()),
  orgId,
  name,
  shortCode,
  description,
}

@genType
let rename = (~product, ~name) => {...product, name}

@genType
let changeShortCode = (~product, ~shortCode) => {...product, shortCode}

@genType
let setDescription = (~product, ~description) => {...product, description: Some(description)}

@genType
let clearDescription = product => {...product, description: None}
