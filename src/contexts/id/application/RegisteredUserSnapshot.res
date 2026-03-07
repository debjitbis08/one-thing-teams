module D = IdDomain
module LoginDomain = Login
module List = Belt.List
module Array = Belt.Array
module Option = Belt.Option

@genType
type userSnapshot = {
  userId: string,
  email: string,
  username: string,
  displayName: string,
  status: string,
}

@genType
type organizationSnapshot = {
  organizationId: string,
}

@genType
type membershipSnapshot = {
  organizationId: string,
  role: string,
}

@genType
type passwordProviderSnapshot = {
  providerAssignedId: string,
  passwordHash: string,
}

@genType
type snapshot = {
  user: userSnapshot,
  defaultOrganizationId: string,
  preferredOrganizationId: string,
  memberships: array<membershipSnapshot>,
  passwordProvider: option<passwordProviderSnapshot>,
  isContributor: bool,
  createdAt: float,
  updatedAt: float,
}

@genType
type orgDetails = {
  organizationId: string,
  name: string,
  shortCode: string,
  ownerId: string,
}

let userStatusToString = status =>
  switch status {
  | D.STAGED => "STAGED"
  | D.CONFIRMED => "CONFIRMED"
  | D.ACTIVE => "ACTIVE"
  | D.RECOVERY => "RECOVERY"
  | D.DISABLED => "DISABLED"
  }

let userStatusOfString = status =>
  switch status {
  | "STAGED" => Some(D.STAGED)
  | "CONFIRMED" => Some(D.CONFIRMED)
  | "ACTIVE" => Some(D.ACTIVE)
  | "RECOVERY" => Some(D.RECOVERY)
  | "DISABLED" => Some(D.DISABLED)
  | _ => None
  }

let roleToString = role =>
  switch role {
  | D.OWNER => "OWNER"
  | D.ADMIN => "ADMIN"
  | D.EDITOR => "EDITOR"
  | D.VIEWER => "VIEWER"
  | D.GUEST => "GUEST"
  }

let roleOfString = role =>
  switch role {
  | "OWNER" => Some(D.OWNER)
  | "ADMIN" => Some(D.ADMIN)
  | "EDITOR" => Some(D.EDITOR)
  | "VIEWER" => Some(D.VIEWER)
  | "GUEST" => Some(D.GUEST)
  | _ => None
  }

let userToSnapshot = (user: D.user) => {
  let UserId.UserId(userUuid) = user.userId
  {
    userId: UUIDv7.value(userUuid),
    email: Email.value(user.email),
    username: user.username,
    displayName: user.displayName,
    status: userStatusToString(user.status),
  }
}

let userOfSnapshot = (snapshot: userSnapshot) =>
  switch (UUIDv7.ofString(snapshot.userId), Email.make(snapshot.email), userStatusOfString(snapshot.status)) {
  | (Error(_), _, _) => None
  | (_, Error(_), _) => None
  | (_, _, None) => None
  | (Ok(userUuid), Ok(email), Some(status)) =>
      Some({
        userId: UserId.UserId(userUuid),
        email,
        username: snapshot.username,
        displayName: snapshot.displayName,
        status,
      }: D.user)
  }

let orgIdOfOrganization = (organization: Organization.t): string => {
  let OrganizationId.OrganizationId(orgUuid) = Organization.id(organization)
  UUIDv7.value(orgUuid)
}

let organizationOfDetails = (details: orgDetails): option<Organization.t> =>
  switch UUIDv7.ofString(details.ownerId) {
  | Error(_) => None
  | Ok(ownerUuid) =>
      let owner = UserId.UserId(ownerUuid)
      switch Organization.create(~name=details.name, ~owner, ~id=?Some(details.organizationId), ()) {
      | Error(_) => None
      | Ok(organization) => Some(organization)
      }
  }

let findOrgDetails = (orgs: array<orgDetails>, orgId: string): option<orgDetails> =>
  Array.getBy(orgs, o => o.organizationId == orgId)

let membershipsToSnapshot = (memberships: list<D.membership>) =>
  memberships
  ->List.toArray
  ->Array.map(membership => {
      organizationId: orgIdOfOrganization(membership.organization),
      role: roleToString(membership.role),
    })

let membershipsOfSnapshot = (
  snapshots: array<membershipSnapshot>,
  orgs: array<orgDetails>,
): option<list<D.membership>> =>
  Array.reduceReverse(snapshots, Some(list{}), (acc, snapshot) =>
    switch acc {
    | None => None
    | Some(current) =>
        switch (
          findOrgDetails(orgs, snapshot.organizationId)->Option.flatMap(organizationOfDetails),
          roleOfString(snapshot.role),
        ) {
        | (Some(organization), Some(role)) =>
            let membership: D.membership = {organization, role}
            Some(List.add(current, membership))
        | _ => None
        }
    }
  )

let passwordProviderToSnapshot = (registeredUser: D.registeredUser) =>
  registeredUser
  ->LoginDomain.passwordProvider
  ->Option.map(provider => {
      providerAssignedId: provider.providerAssignedId,
      passwordHash: provider.passwordHash,
    })

let passwordProviderOfSnapshot = snapshot =>
  switch snapshot {
  | None => Some(list{})
  | Some(provider) =>
      Some(list{D.PasswordProvider({
        providerAssignedId: provider.providerAssignedId,
        passwordHash: provider.passwordHash,
      })})
  }

@genType
let snapshotOfRegisteredUser = (registeredUser: D.registeredUser): snapshot => {
  let user = userToSnapshot(registeredUser.user)
  let memberships = membershipsToSnapshot(registeredUser.memberships)
  let passwordProvider = passwordProviderToSnapshot(registeredUser)
  {
    user,
    defaultOrganizationId: orgIdOfOrganization(registeredUser.defaultOrganization),
    preferredOrganizationId: orgIdOfOrganization(registeredUser.preferredOrganization),
    memberships,
    passwordProvider,
    isContributor: registeredUser.isContributor,
    createdAt: registeredUser.createdAt,
    updatedAt: registeredUser.updatedAt,
  }
}

@genType
let registeredUserOfSnapshot = (
  snapshot: snapshot,
  orgs: array<orgDetails>,
): option<D.registeredUser> => {
  let defaultOrg =
    findOrgDetails(orgs, snapshot.defaultOrganizationId)->Option.flatMap(organizationOfDetails)
  let preferredOrg =
    findOrgDetails(orgs, snapshot.preferredOrganizationId)->Option.flatMap(organizationOfDetails)

  switch (
    userOfSnapshot(snapshot.user),
    defaultOrg,
    preferredOrg,
    membershipsOfSnapshot(snapshot.memberships, orgs),
    passwordProviderOfSnapshot(snapshot.passwordProvider),
  ) {
  | (Some(user), Some(defaultOrganization), Some(preferredOrganization), Some(memberships), Some(authProviders)) =>
      Some({
        user,
        authProviders,
        defaultOrganization,
        preferredOrganization,
        memberships,
        isContributor: snapshot.isContributor,
        createdAt: snapshot.createdAt,
        updatedAt: snapshot.updatedAt,
      }: D.registeredUser)
  | _ => None
  }
}
