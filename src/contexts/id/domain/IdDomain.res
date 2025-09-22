type userStatus =
  | STAGED
  | CONFIRMED
  | ACTIVE
  | RECOVERY
  | DISABLED

type passwordAuthProvider = {
  providerAssignedId: string,
  passwordHash: string,
}

type googleAuthProvider = {
  providerAssignedId: string,
  token: string,
  avatarUrl: option<string>,
  displayName: option<string>,
}

type authProvider =
  | PasswordProvider(passwordAuthProvider)
  | GoogleProvider(googleAuthProvider)

type user = {
  userId: UserId.userId,
  email: Email.t,
  username: string,
  displayName: string,
  status: userStatus,
}

type memberRole =
  | OWNER
  | ADMIN
  | EDITOR
  | VIEWER
  | GUEST

type membership = {
  organization: Organization.t,
  role: memberRole,
}

type registeredUser = {
  user: user,
  authProviders: list<authProvider>,
  defaultOrganization: Organization.t,
  preferredOrganization: Organization.t,
  memberships: list<membership>,
  isContributor: bool,
  createdAt: float,
  updatedAt: float,
}

type userSession = {
  userId: UserId.userId,
  username: string,
  displayName: string,
  organization: Organization.t,
  roles: array<string>,
}

type passwordRegistration = {
  email: Email.t,
  username: string,
  displayName: option<string>,
  password: string,
  confirmPassword: option<string>,
  initialOrganizationName: string,
}

type passwordRegistrationError = [
  | #PasswordsDoNotMatch
  | #PasswordTooShort
  | Organization.error
]
