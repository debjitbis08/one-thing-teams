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
  name: string,
  description: option<string>,
}

@genType
type createdEvent = {
  productId: string,
  organizationId: string,
  name: string,
  shortCode: string,
  description: option<string>,
  createdBy: string,
  occurredAt: float,
}

@genType
type createdResult = {
  productId: string,
  name: string,
  shortCode: string,
}

@genType
type dependencies = {
  now: unit => float,
  appendEvent: createdEvent => Promise.t<unit>,
}

@genType
type error = [
  | #Forbidden
  | #InvalidName(string)
  | #InvalidShortCode(string)
]

@genType
let execute = (deps: dependencies, command: command): Promise.t<result<createdResult, error>> => {
  if !hasAllowedRole(command.session.roles) {
    Promise.resolve(Error(#Forbidden))
  } else {
    let shortCodeRaw = ShortCode.Spec.normalize(command.name)
    switch Product.validateCreate(~name=command.name, ~shortCode=shortCodeRaw) {
    | Error(#InvalidName(n)) => Promise.resolve(Error(#InvalidName(n)))
    | Error(#InvalidShortCode(s)) => Promise.resolve(Error(#InvalidShortCode(s)))
    | Ok((validName, validShortCode)) =>
      let now = deps.now()
      let productId = UUIDv7.value(UUIDv7.gen())

      let event: createdEvent = {
        productId,
        organizationId: command.session.organizationId,
        name: Product.Name.value(validName),
        shortCode: ShortCode.value(validShortCode),
        description: command.description,
        createdBy: command.session.userId,
        occurredAt: now,
      }

      deps.appendEvent(event)->Promise.thenResolve(_ =>
        Ok({
          productId,
          name: event.name,
          shortCode: event.shortCode,
        })
      )
    }
  }
}
