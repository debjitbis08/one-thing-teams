module D = IdDomain
module List = Belt.List
module Option = Belt.Option

let memberRoleToString = role =>
  switch role {
  | D.OWNER => "OWNER"
  | D.ADMIN => "ADMIN"
  | D.EDITOR => "EDITOR"
  | D.VIEWER => "VIEWER"
  | D.GUEST => "GUEST"
  }

let passwordProvider = (user: D.registeredUser): option<D.passwordAuthProvider> =>
  switch List.getBy(user.authProviders, provider =>
    switch provider {
    | D.PasswordProvider(_) => true
    | _ => false
    }
  ) {
  | None => None
  | Some(D.PasswordProvider(details)) => Some(details)
  | Some(_) => None
  }

let equalOrganizations = (a: Organization.t, b: Organization.t) => {
  let OrganizationId.OrganizationId(idA) = Organization.id(a)
  let OrganizationId.OrganizationId(idB) = Organization.id(b)
  UUIDv7.equal(idA, idB)
}

let membershipForPreferredOrganization = (user: D.registeredUser): option<D.membership> =>
  List.getBy(user.memberships, membership => equalOrganizations(membership.organization, user.preferredOrganization))

let rolesForUser = (membership: D.membership, isContributor: bool): array<string> => {
  let membershipRole = memberRoleToString(membership.role)
  let roleList =
    if isContributor {
      list{membershipRole, "ROLE_CONTRIBUTOR"}
    } else {
      list{membershipRole}
    }
  Belt.List.toArray(roleList)
}

let sessionForPreferredOrganization = (user: D.registeredUser): option<D.userSession> =>
  membershipForPreferredOrganization(user)
  ->Option.map(membership => ({
        userId: user.user.userId,
        username: user.user.username,
        displayName: user.user.displayName,
        organization: membership.organization,
        roles: rolesForUser(membership, user.isContributor),
      }: D.userSession))
