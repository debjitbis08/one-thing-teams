module JSON = RescriptCore.JSON
module Promise = RescriptCore.Promise
module Array = Belt.Array
module Encode = RescriptCore.JSON.Encode

let hasAllowedRole = roles => roles->Array.some(role => role == "OWNER" || role == "ADMIN")

type session = RevokeInvitation.session

type dependencies = RevokeInvitation.dependencies

type astroContext = {
  session: option<session>,
  invitationId: string,
}

type response = {
  status: int,
  body: JSON.t,
}

let makeResponse = (~status, body) => {status, body}

let errorResponse = error => makeResponse(~status=SystemError.httpStatus(error), SystemError.encode(error))

let encodeSuccess = () => {
  let dict = Dict.make()
  dict->Dict.set("success", Encode.bool(true))
  Encode.object(dict)
}

let delete = (deps: dependencies, ctx: astroContext): Promise.t<response> => {
  switch ctx.session {
  | None => Promise.resolve(errorResponse(SystemError.unauthorized("Unauthorized")))
  | Some(session) =>
    if !hasAllowedRole(session.roles) {
      Promise.resolve(errorResponse(SystemError.forbidden("Forbidden")))
    } else {
      let command: RevokeInvitation.command = {
        session,
        invitationId: ctx.invitationId,
      }
      RevokeInvitation.execute(deps, command)
      ->Promise.then(result =>
        switch result {
        | Ok(_) => Promise.resolve(makeResponse(~status=200, encodeSuccess()))
        | Error(#Forbidden) => Promise.resolve(errorResponse(SystemError.forbidden("Forbidden")))
        | Error(#InvitationNotFound) =>
          Promise.resolve(errorResponse(SystemError.notFound("Invitation not found")))
        | Error(#AlreadyAccepted) =>
          Promise.resolve(errorResponse(SystemError.conflict("Invitation has already been accepted")))
        | Error(#AlreadyRevoked) =>
          Promise.resolve(errorResponse(SystemError.validation("Invitation has already been revoked")))
        | Error(#InvitationExpired) =>
          Promise.resolve(errorResponse(SystemError.validation("Invitation has expired")))
        }
      )
    }
  }
  ->Promise.catch(error => {
    Js.log2("Revoke invitation controller unexpected error", error)
    Promise.resolve(errorResponse(SystemError.internal("Unable to revoke invitation")))
  })
}

@genType
let deleteJs = delete
