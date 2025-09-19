open Organization
open UserId
open Email

@genType
 type organizationMember = {
  organizationId: organizationId,
  userId: userId,
  name: string,
  email: Email.t,
}

@genType
let make = (~organizationId, ~userId, ~name, ~email, ()) => {
  organizationId,
  userId,
  name,
  email,
}

@genType
let rename = (~member, ~name) => {...member, name}

@genType
let updateEmail = (~member, ~email) => {...member, email}
