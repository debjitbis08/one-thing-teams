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

@genType
let execute = (deps: dependencies, command: command): Promise.t<result<createdResult, error>> => {
  if !hasAllowedRole(command.session.roles) {
    Promise.resolve(Error(#Forbidden))
  } else {
    let timeBudget = switch command.timeBudget {
    | Some(t) => t
    | None => 0.0
    }

    switch Initiative.validateCreate(~title=command.title, ~timeBudget) {
    | Error(#InvalidTitle(t)) => Promise.resolve(Error(#InvalidTitle(t)))
    | Error(#InvalidTimeBudget) => Promise.resolve(Error(#InvalidTimeBudget))
    | Ok(_validTitle) =>
      deps.productExists(command.productId)->Promise.then(exists =>
        if !exists {
          Promise.resolve(Error(#ProductNotFound))
        } else {
          let now = deps.now()
          let initiativeId = UUIDv7.value(UUIDv7.gen())

          let event: createdEvent = {
            initiativeId,
            productId: command.productId,
            organizationId: command.session.organizationId,
            title: Initiative.Title.value(_validTitle),
            description: command.description,
            timeBudget,
            chatRoomLink: command.chatRoomLink,
            createdBy: command.session.userId,
            occurredAt: now,
          }

          deps.appendEvent(event)->Promise.thenResolve(_ =>
            Ok({
              initiativeId,
              productId: command.productId,
              title: event.title,
            })
          )
        }
      )
    }
  }
}
