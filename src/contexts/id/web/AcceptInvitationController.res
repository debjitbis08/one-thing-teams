module Dict = RescriptCore.Dict
module JSON = RescriptCore.JSON
module Promise = RescriptCore.Promise
module Encode = RescriptCore.JSON.Encode

type session = AcceptInvitation.session

type dependencies = AcceptInvitation.dependencies

type astroContext = {
  request: Fetch.Request.t,
  session: option<session>,
}

type response = {
  status: int,
  body: JSON.t,
}

let decodeStringField = (dict, key) =>
  switch Dict.get(dict, key) {
  | Some(value) => JSON.Decode.string(value)
  | None => None
  }

let makeResponse = (~status, body) => {status, body}

let errorResponse = error => makeResponse(~status=SystemError.httpStatus(error), SystemError.encode(error))

let encodeSuccess = (result: AcceptInvitation.acceptedResult) => {
  let dict = Dict.make()
  dict->Dict.set("organizationId", Encode.string(result.organizationId))
  dict->Dict.set("organizationName", Encode.string(result.organizationName))
  dict->Dict.set("role", Encode.string(result.role))
  Encode.object(dict)
}

let post = (deps: dependencies, ctx: astroContext): Promise.t<response> => {
  switch ctx.session {
  | None => Promise.resolve(errorResponse(SystemError.unauthorized("Unauthorized")))
  | Some(session) =>
    Fetch.Request.json(ctx.request)
    ->Promise.then(json =>
      switch JSON.Decode.object(json) {
      | None => Promise.resolve(errorResponse(SystemError.validation("Request body must be a JSON object")))
      | Some(dict) =>
        switch decodeStringField(dict, "token") {
        | None => Promise.resolve(errorResponse(SystemError.validation("Field 'token' is required")))
        | Some(token) =>
          let command: AcceptInvitation.command = {
            session,
            token,
          }
          AcceptInvitation.execute(deps, command)
          ->Promise.then(result =>
            switch result {
            | Ok(accepted) => Promise.resolve(makeResponse(~status=200, encodeSuccess(accepted)))
            | Error(#InvitationNotFound) =>
              Promise.resolve(errorResponse(SystemError.notFound("Invitation not found")))
            | Error(#AlreadyAccepted) =>
              Promise.resolve(errorResponse(SystemError.conflict("Invitation has already been accepted")))
            | Error(#AlreadyRevoked) =>
              Promise.resolve(errorResponse(SystemError.validation("Invitation has been revoked")))
            | Error(#InvitationExpired) =>
              Promise.resolve(errorResponse(SystemError.validation("Invitation has expired")))
            | Error(#EmailMismatch) =>
              Promise.resolve(errorResponse(SystemError.forbidden("This invitation was sent to a different email address")))
            }
          )
        }
      }
    )
    ->Promise.catch(_error =>
      Promise.resolve(errorResponse(SystemError.validation("Request body must be valid JSON")))
    )
  }
  ->Promise.catch(error => {
    Js.log2("Accept invitation controller unexpected error", error)
    Promise.resolve(errorResponse(SystemError.internal("Unable to accept invitation")))
  })
}

@genType
let postJs = post
