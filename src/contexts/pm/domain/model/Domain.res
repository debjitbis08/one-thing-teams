type organizationId = OrganizationId(UUIDv7.t)

type organization = {
    organizationId: organizationId,
    name: string,
    shortCode: ShortCode.t,
}

type productId = ProductId(UUIDv7.t)

type product = {
  productId: productId,
  orgId: organizationId,
  name: string,
  shortCode: ShortCode.t,
  description: option<string>,
}

type organizationMember = {
  orgId: organizationId,
  userId: UserId.userId,
  name: string,
  email: Email.t,
}

type teamId = TeamId(UUIDv7.t)
type team = {
  id: teamId,
  orgId: organizationId,
  name: string,
  members: RescriptCore.Set.t<organizationMember>,
}

type progressStatus =
    | Thinking
    | Trying
    | Building
    | Finishing
    | Deploying
    | Stuck

type lifecycleStatus =
    | Waiting
    | Active
    | Done
    | Abandoned
    | Pruned


type initiativePriority = {
    userValue: FibonacciScale.t,
    timeCriticality: FibonacciScale.t,
    riskReductionOrOpportunityEnablement: FibonacciScale.t,
    effort: FibonacciScale.t,
    isCore: bool,
}

type initiativeId = InitiativeId(UUIDv7.t)
type initiative = {
  initiativeId: initiativeId,
  productId: productId,
  title: string,
  description: option<string>,
  timeBudget: float,
  chatRoomLink: option<string>,
  progressStatus: progressStatus,
  lifecycleStatus: lifecycleStatus,
  isValidated: bool,
  validationEvidence: option<string>,
  outcomeNotes: option<string>,
  assignedTeamId: option<teamId>,
  priority: initiativePriority,
}