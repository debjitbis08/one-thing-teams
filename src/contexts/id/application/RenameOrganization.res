module Promise = RescriptCore.Promise
module String = RescriptCore.String
module Array = Belt.Array
module Option = Belt.Option

module OrganizationDomain = Organization

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
  organizationId: string,
  name: string,
}

@genType
type renameEvent = {
  organizationId: string,
  name: string,
  shortCode: string,
  renamedBy: string,
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
type snapshotState = {
  organizationId: string,
  name: string,
  shortCode: string,
  ownerId: string,
}

@genType
type aggregateSnapshot = {
  version: int,
  state: snapshotState,
}

@genType
type aggregateData = {
  version: int,
  snapshot: option<aggregateSnapshot>,
  events: array<storedEvent>,
}

type renamedEventPayload = {
  name: string,
  shortCode: string,
}

@genType
type dependencies = {
  now: unit => float,
  loadAggregate: string => Promise.t<option<aggregateData>>,
  appendEvent: renameEvent => Promise.t<unit>,
}

@genType
type error = [
  | #Forbidden
  | #OrganizationNotFound
  | #InvalidName(string)
  | #InvalidShortCode(string)
]

let decodeStringField = (dict, key) =>
  switch Dict.get(dict, key) {
  | Some(value) => JSON.Decode.string(value)
  | None => None
  }

let decodeCreatedEvent = data =>
  switch JSON.Decode.object(data) {
  | None => None
  | Some(dict) =>
      switch (decodeStringField(dict, "organizationId"), decodeStringField(dict, "name"), decodeStringField(dict, "shortCode"), decodeStringField(dict, "ownerId")) {
      | (Some(organizationId), Some(name), Some(shortCode), Some(ownerId)) => Some({organizationId, name, shortCode, ownerId})
      | _ => None
      }
  }

let decodeRenamedEvent = (data: JSON.t): option<renamedEventPayload> =>
  switch JSON.Decode.object(data) {
  | None => None
  | Some(dict) =>
      switch (decodeStringField(dict, "name"), decodeStringField(dict, "shortCode")) {
      | (Some(name), Some(shortCode)) => Some({name, shortCode})
      | _ => None
      }
  }

let organizationFromSnapshot = snapshot => {
  switch OrganizationDomain.create(
    ~name=snapshot.state.name,
    ~owner=UserId.UserId(UUIDv7.ofStringUnsafe(snapshot.state.ownerId)),
    ~id=?Some(snapshot.state.organizationId),
    (),
  ) {
  | Belt.Result.Ok(organization) => Some((organization, snapshot.version))
  | Belt.Result.Error(_) => None
  }
}

let applyCreatedEvent = (event, _current) =>
  switch decodeCreatedEvent(event.data) {
  | None => None
  | Some(payload) =>
      switch OrganizationDomain.create(
        ~name=payload.name,
        ~owner=UserId.UserId(UUIDv7.ofStringUnsafe(payload.ownerId)),
        ~id=?Some(payload.organizationId),
        (),
      ) {
      | Belt.Result.Ok(organization) => Some((organization, event.version))
      | Belt.Result.Error(_) => None
      }
  }

let applyRenamedEvent = (event, current) =>
  switch current {
  | None => None
  | Some((organization, _version)) =>
      switch decodeRenamedEvent(event.data) {
      | None => None
      | Some(payload) =>
          switch OrganizationDomain.renameEventOfStrings(~name=payload.name, ~shortCode=payload.shortCode) {
          | None => None
          | Some(domainEvent) =>
              Some((OrganizationDomain.applyRenameEvent(~organization, domainEvent), event.version))
          }
      }
  }

let foldEvents = (initial, events) =>
  Array.reduce(events, initial, (state, event) =>
    switch event.type_ {
    | "identity.organization.created" => applyCreatedEvent(event, state)
    | "identity.organization.renamed" => applyRenamedEvent(event, state)
    | _ => state
    }
  )

let loadOrganization = (deps: dependencies, organizationId: string): Promise.t<option<(OrganizationDomain.t, int)>> =>
  deps.loadAggregate(organizationId)
  ->Promise.then(aggregateOpt =>
      switch aggregateOpt {
      | None => Promise.resolve(None)
      | Some(aggregate) =>
          let baseState =
            switch aggregate.snapshot {
            | None => None
            | Some(snapshot) => organizationFromSnapshot(snapshot)
            }
          switch foldEvents(baseState, aggregate.events) {
          | None => Promise.resolve(None)
          | Some((organization, version)) =>
              let finalVersion =
                if version < aggregate.version {
                  aggregate.version
                } else {
                  version
                }
              Promise.resolve(Some((organization, finalVersion)))
          }
      }
    )

@genType
let execute = (deps: dependencies, command: command): Promise.t<result<unit, error>> => {
  if command.session.organizationId != command.organizationId {
    Promise.resolve(Error(#Forbidden))
  } else if !hasAllowedRole(command.session.roles) {
    Promise.resolve(Error(#Forbidden))
  } else {
    loadOrganization(deps, command.organizationId)
    ->Promise.then(result =>
        switch result {
        | None => Promise.resolve(Error(#OrganizationNotFound))
        | Some((organization, currentVersion)) =>
            switch OrganizationDomain.rename(~organization, ~name=command.name) {
            | Belt.Result.Error(#InvalidName(original)) => Promise.resolve(Error(#InvalidName(original)))
            | Belt.Result.Error(#InvalidShortCode(original)) => Promise.resolve(Error(#InvalidShortCode(original)))
            | Belt.Result.Ok(domainEvent) =>
                let occurredAt = deps.now()
                let eventPayload = OrganizationDomain.renameEventToStrings(domainEvent)
                let event: renameEvent = {
                  organizationId: command.organizationId,
                  name: eventPayload.name,
                  shortCode: eventPayload.shortCode,
                  renamedBy: command.session.userId,
                  sessionId: command.session.sessionId,
                  expectedVersion: currentVersion,
                  version: currentVersion + 1,
                  occurredAt,
                }
                deps.appendEvent(event)
                ->Promise.thenResolve(_ => Ok(()))
            }
        }
      )
  }
}
