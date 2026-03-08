module Promise = RescriptCore.Promise
module Array = Belt.Array

let hasAllowedRole = roles => roles->Array.some(role => role == "OWNER" || role == "ADMIN")

type session = {
  sessionId: string,
  userId: string,
  organizationId: string,
  roles: array<string>,
}

type scoreNote = {
  value: int,
  note: option<string>,
}

@genType
type command = {
  session: session,
  initiativeId: string,
  scoreType: string,
  userValue: option<scoreNote>,
  timeCriticality: option<scoreNote>,
  riskReduction: option<scoreNote>,
  effort: option<scoreNote>,
  isCore: option<bool>,
  contributionCount: option<float>,
}

@genType
type scoredEvent = {
  initiativeId: string,
  organizationId: string,
  scoreType: string,
  userValue: option<scoreNote>,
  timeCriticality: option<scoreNote>,
  riskReduction: option<scoreNote>,
  effort: option<scoreNote>,
  isCore: option<bool>,
  contributionCount: option<float>,
  scoredBy: string,
  sessionId: string,
  expectedVersion: int,
  version: int,
  occurredAt: float,
}

@genType
type storedEvent = {
  version: int,
  type_: string,
  data: JSON.t,
}

@genType
type aggregateData = {
  version: int,
  events: array<storedEvent>,
}

@genType
type dependencies = {
  now: unit => float,
  loadAggregate: string => Promise.t<option<aggregateData>>,
  appendEvent: scoredEvent => Promise.t<unit>,
}

@genType
type error = [
  | #Forbidden
  | #InitiativeNotFound
  | #InvalidScoreType
  | #MissingProxyFields
  | #MissingBreakEvenFields
  | #InvalidFibonacciValue(int)
]

let validateFibonacci = value =>
  switch FibonacciScale.make(value) {
  | Ok(_) => true
  | Error(_) => false
  }

let validateScoreNote = (note: scoreNote) => validateFibonacci(note.value)

let validateProxy = (command: command) =>
  switch (command.userValue, command.timeCriticality, command.riskReduction, command.effort) {
  | (Some(uv), Some(tc), Some(rr), Some(e)) =>
    if !validateScoreNote(uv) {
      Error(#InvalidFibonacciValue(uv.value))
    } else if !validateScoreNote(tc) {
      Error(#InvalidFibonacciValue(tc.value))
    } else if !validateScoreNote(rr) {
      Error(#InvalidFibonacciValue(rr.value))
    } else if !validateScoreNote(e) {
      Error(#InvalidFibonacciValue(e.value))
    } else {
      Ok()
    }
  | _ => Error(#MissingProxyFields)
  }

let validateBreakEven = (command: command) =>
  switch (command.contributionCount, command.effort) {
  | (Some(_cc), Some(e)) =>
    if !validateScoreNote(e) {
      Error(#InvalidFibonacciValue(e.value))
    } else {
      Ok()
    }
  | _ => Error(#MissingBreakEvenFields)
  }

let initiativeExists = (aggregate: option<aggregateData>) =>
  switch aggregate {
  | None => false
  | Some(agg) =>
    agg.events->Array.some(event => event.type_ == "pm.initiative.created")
  }

let authorize = (command: command) =>
  if hasAllowedRole(command.session.roles) {
    Ok(command)
  } else {
    Error(#Forbidden)
  }

let validateScore = (command: command) =>
  switch command.scoreType {
  | "proxy" => validateProxy(command)
  | "break_even" => validateBreakEven(command)
  | _ => Error(#InvalidScoreType)
  }

let requireInitiative = (aggregateOpt: option<aggregateData>) =>
  if initiativeExists(aggregateOpt) {
    let version = switch aggregateOpt {
    | Some(agg) => agg.version
    | None => 0
    }
    Ok(version)
  } else {
    Error(#InitiativeNotFound)
  }

@genType
let execute = (deps: dependencies, command: command): Promise.t<result<unit, error>> =>
  authorize(command)
  ->AsyncResult.fromResult
  ->AsyncResult.flatMap(cmd => validateScore(cmd)->AsyncResult.fromResult)
  ->AsyncResult.flatMap(_ =>
    deps.loadAggregate(command.initiativeId)
    ->Promise.thenResolve(requireInitiative)
  )
  ->AsyncResult.flatMap(currentVersion => {
    let event: scoredEvent = {
      initiativeId: command.initiativeId,
      organizationId: command.session.organizationId,
      scoreType: command.scoreType,
      userValue: command.userValue,
      timeCriticality: command.timeCriticality,
      riskReduction: command.riskReduction,
      effort: command.effort,
      isCore: command.isCore,
      contributionCount: command.contributionCount,
      scoredBy: command.session.userId,
      sessionId: command.session.sessionId,
      expectedVersion: currentVersion,
      version: currentVersion + 1,
      occurredAt: deps.now(),
    }
    deps.appendEvent(event)->Promise.thenResolve(_ => Ok())
  })
