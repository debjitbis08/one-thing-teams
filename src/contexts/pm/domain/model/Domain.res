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

type cycleId = CycleId(UUIDv7.t)
type cycle = {
  cycleId: cycleId,
  productId: productId,
  startDate: Date.t,
  endDate: Date.t,
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

type initiativePriority = {
  userValue: FibonacciScale.t,
  timeCriticality: FibonacciScale.t,
  riskReductionOrOpportunityEnablement: FibonacciScale.t,
  effort: FibonacciScale.t,
  isCore: bool,
}

type doneEvidence = option<string>

type initiativeId = InitiativeId(UUIDv7.t)
type initiative = {
  initiativeId: initiativeId,
  productId: productId,
  cycleId: option<cycleId>,
  title: string,
  description: option<string>,
  timeBudget: float,
  chatRoomLink: option<string>,
  progressStatus: progressStatus,
  lifecycleStatus: lifecycleStatus,
  doneEvidence: doneEvidence,
  outcomeNotes: option<string>,
  priority: initiativePriority,
}

type emergencyId = EmergencyId(UUIDv7.t)
type emergency = {
  emergencyId: emergencyId,
  productId: productId,
  title: string,
  description: option<string>,
  reportedAt: string,
  resolvedAt: option<string>,
}

type assignment =
  | Unassigned
  | Support(productId)
  | Initiative(initiativeId)

type organizationMember = {
  orgId: organizationId,
  userId: UserId.userId,
  name: string,
  email: Email.t,
  assignment: assignment,
  emergency: option<emergencyId>,
}

type taskStatus =
  | Todo
  | Doing
  | Stuck
  | Done
  | Pruned

type taskId = TaskId(UUIDv7.t)

type taskData = {
  taskId: taskId,
  title: string,
  description: option<string>,
  status: taskStatus,
  startedAt: option<string>,
  completedAt: option<string>,
  assignees: RescriptCore.Set.t<UserId.userId>,
}

type scenario = {
  title: string,
  acceptanceCriteria: array<string>,
}

type taskKind =
  | InitiativeTask(initiativeId)
  | UserStory({initiativeId: initiativeId, scenarios: array<scenario>})
  | Emergency(emergency)
  | Support(productId)

module Task = {
  type t = {
    data: taskData,
    kind: taskKind,
  }

  let data = t => t.data
  let kind = t => t.kind

  type assignmentError =
  | AssignmentMismatch
  | MemberNotAssigned

  let isCompatible = (~member: organizationMember, ~kind: taskKind) =>
    switch (member.assignment, kind) {
    | (Initiative(initiativeId), InitiativeTask(taskInitiativeId))
    | (Initiative(initiativeId), UserStory({initiativeId: taskInitiativeId, scenarios: _})) =>
      initiativeId == taskInitiativeId
    | (Support(productId), Support(taskProductId)) => productId == taskProductId
    | (Support(_), InitiativeTask(_)) => false
    | (Support(_), UserStory(_)) => false
    | (Initiative(_), Support(_)) => false
    | (_, Emergency(_)) => true
    | (Unassigned, _) => true
    }

  let make = (~data, ~kind, ~getMember: UserId.userId => option<organizationMember>, ()) =>
    /* ensure the provided set contains only compatible ids */
    switch RescriptCore.Set.toArray(data.assignees)->RescriptCore.Array.every(userId =>
      switch getMember(userId) {
      /* you'll need to provide this lookup */
      | Some(member) => isCompatible(~member, ~kind)
      | None => false
      }
    ) {
    | true => Belt.Result.Ok({data, kind})
    | false => Belt.Result.Error(AssignmentMismatch)
    }

  let assign = (~task, ~member) =>
    if isCompatible(~member, ~kind=task.kind) {
      task.data.assignees->RescriptCore.Set.add(member.userId)
      Belt.Result.Ok(task)
    } else {
      Belt.Result.Error(AssignmentMismatch)
    }
}
