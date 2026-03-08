module Promise = RescriptCore.Promise
module Array = Belt.Array

let hasAllowedRole = roles => roles->Array.some(role => role == "OWNER" || role == "ADMIN")

type session = {
  sessionId: string,
  userId: string,
  organizationId: string,
  roles: array<string>,
}

@genType
type command = {
  session: session,
  productId: string,
  title: string,
  description: option<string>,
  timeBudget: option<float>,
  chatRoomLink: option<string>,
}

@genType
type createdEvent = {
  initiativeId: string,
  productId: string,
  organizationId: string,
  title: string,
  description: option<string>,
  timeBudget: float,
  chatRoomLink: option<string>,
  createdBy: string,
  occurredAt: float,
}

@genType
type createdResult = {
  initiativeId: string,
  productId: string,
  title: string,
}

@genType
type dependencies = {
  now: unit => float,
  productExists: string => Promise.t<bool>,
  appendEvent: createdEvent => Promise.t<unit>,
}

@genType
type error = [
  | #Forbidden
  | #InvalidTitle(string)
  | #InvalidTimeBudget
  | #ProductNotFound
]

let authorize = (command: command) =>
  if hasAllowedRole(command.session.roles) {
    Ok(command)
  } else {
    Error(#Forbidden)
  }

let validate = (command: command) => {
  let timeBudget = switch command.timeBudget {
  | Some(t) => t
  | None => 0.0
  }
  switch Initiative.validateCreate(~title=command.title, ~timeBudget) {
  | Error(#InvalidTitle(t)) => Error(#InvalidTitle(t))
  | Error(#InvalidTimeBudget) => Error(#InvalidTimeBudget)
  | Ok(validTitle) => Ok((validTitle, timeBudget))
  }
}

@genType
let execute = (deps: dependencies, command: command): Promise.t<result<createdResult, error>> =>
  authorize(command)
  ->AsyncResult.fromResult
  ->AsyncResult.flatMap(cmd => validate(cmd)->AsyncResult.fromResult)
  ->AsyncResult.flatMap(((validTitle, timeBudget)) =>
    deps.productExists(command.productId)
    ->Promise.thenResolve(exists =>
      if exists { Ok((validTitle, timeBudget)) } else { Error(#ProductNotFound) }
    )
  )
  ->AsyncResult.flatMap(((validTitle, timeBudget)) => {
    let initiativeId = UUIDv7.value(UUIDv7.gen())
    let event: createdEvent = {
      initiativeId,
      productId: command.productId,
      organizationId: command.session.organizationId,
      title: Initiative.Title.value(validTitle),
      description: command.description,
      timeBudget,
      chatRoomLink: command.chatRoomLink,
      createdBy: command.session.userId,
      occurredAt: deps.now(),
    }
    deps.appendEvent(event)->Promise.thenResolve(_ =>
      Ok({initiativeId, productId: command.productId, title: event.title})
    )
  })
