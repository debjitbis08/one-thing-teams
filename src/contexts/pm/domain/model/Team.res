open GlobalUniqueId
open Organization
open OrganizationMember
open UserId

let memberKey = member => member.userId->UserId.value

let ensureSameOrg = (orgId, member) =>
  if GlobalUniqueId.equal(orgId, member.organizationId) {
    ()
  } else {
    let message =
      "Member "
      ++ memberKey(member)
      ++ " does not belong to organization "
      ++ GlobalUniqueId.value(orgId)
    Js.Exn.raiseError(message)
  }

let dedupeMembers = (orgId, members) => {
  let seen = Js.Dict.empty()
  members
  ->Belt.Array.keep(member => {
      ensureSameOrg(orgId, member)
      let key = memberKey(member)
      switch Js.Dict.get(seen, key) {
      | Some(_) => false
      | None => {
          Js.Dict.set(seen, key, true)
          true
        }
      }
    })
}

@genType
 type teamId = GlobalUniqueId.t

@genType
 type team = {
  id: teamId,
  orgId: organizationId,
  name: string,
  members: array<organizationMember>,
}

@genType
let makeId = (~id=?, ()) => GlobalUniqueId.make(~id?, ())

@genType
let make = (~orgId, ~name, ~members=?, ~id=?, ()) => {
  let initialMembers = Belt.Option.getWithDefault(members, [||])
  let normalizedMembers = dedupeMembers(orgId, initialMembers)

  {
    id: makeId(~id?, ()),
    orgId,
    name,
    members: normalizedMembers,
  }
}

@genType
let rename = (~team, ~name) => {...team, name}

@genType
let hasMember = (~team, ~member) =>
  team.members->Belt.Array.some(existing => memberKey(existing) == memberKey(member))

let assertMemberBelongs = (team, member) => ensureSameOrg(team.orgId, member)

@genType
let addMember = (~team, ~member) => {
  assertMemberBelongs(team, member)
  if hasMember(~team, ~member) {
    team
  } else {
    {
      ...team,
      members: Belt.Array.concat(team.members, [|member|]),
    }
  }
}

@genType
let removeMember = (~team, ~member) => {
  {
    ...team,
    members:
      team.members->Belt.Array.keep(existing => memberKey(existing) != memberKey(member)),
  }
}

@genType
let memberCount = team => Belt.Array.length(team.members)

@genType
let listMembers = team => team.members
