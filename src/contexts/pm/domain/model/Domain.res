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

type taskStatus =
    | Todo
    | Doing
    | Stuck
    | Done

type taskId = TaskId(UUIDv7.t)

type taskData = {
  taskId: taskId,
  initiativeId: initiativeId,
  title: string,
  description: option<string>,
  status: taskStatus,
  startedAt: option<string>,
  completedAt: option<string>,
  assignees: RescriptCore.Set.t<organizationMember>
}

type scenario = {
    title: string,
    acceptanceCriteria: array<string>,
}

type taskKind =
    | WorkItem
    | UserStory({ scenarios: array<scenario> })

type task = {
    data: taskData,
    kind: taskKind
}