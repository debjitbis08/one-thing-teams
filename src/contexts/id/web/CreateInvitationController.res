module Dict = RescriptCore.Dict
module JSON = RescriptCore.JSON
module Promise = RescriptCore.Promise
module Array = Belt.Array
module Encode = RescriptCore.JSON.Encode

let hasAllowedRole = roles => roles->Array.some(role => role == "OWNER" || role == "ADMIN")

type session = CreateInvitation.session

type dependencies = CreateInvitation.dependencies

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

let encodeSuccess = (result: CreateInvitation.createdResult) => {
  let dict = Dict.make()
  dict->Dict.set("invitationId", Encode.string(result.invitationId))
  dict->Dict.set("token", Encode.string(result.token))
  dict->Dict.set("expiresAt", Encode.float(result.expiresAt))
  Encode.object(dict)
}

let post = (deps: dependencies, ctx: astroContext): Promise.t<response> => {
  switch ctx.session {
  | None => Promise.resolve(errorResponse(SystemError.unauthorized("Unauthorized")))
  | Some(session) =>
    if !hasAllowedRole(session.roles) {
      Promise.resolve(errorResponse(SystemError.forbidden("Forbidden")))
    } else {
      Fetch.Request.json(ctx.request)
      ->Promise.then(json =>
        switch JSON.Decode.object(json) {
        | None => Promise.resolve(errorResponse(SystemError.validation("Request body must be a JSON object")))
        | Some(dict) =>
          switch (decodeStringField(dict, "email"), decodeStringField(dict, "role")) {
          | (Some(email), Some(role)) =>
            let command: CreateInvitation.command = {
              session,
              email,
              role,
            }
            CreateInvitation.execute(deps, command)
            ->Promise.then(result =>
              switch result {
              | Ok(created) => Promise.resolve(makeResponse(~status=201, encodeSuccess(created)))
              | Error(#Forbidden) => Promise.resolve(errorResponse(SystemError.forbidden("Forbidden")))
              | Error(#InvalidEmail(original)) =>
                Promise.resolve(errorResponse(SystemError.validation("Invalid email: " ++ original)))
              | Error(#InvalidRole) =>
                Promise.resolve(errorResponse(SystemError.validation("Invalid role. Must be one of: ADMIN, EDITOR, VIEWER, GUEST")))
              | Error(#OrganizationNotFound) =>
                Promise.resolve(errorResponse(SystemError.notFound("Organization not found")))
              }
            )
          | (None, _) => Promise.resolve(errorResponse(SystemError.validation("Field 'email' is required")))
          | (_, None) => Promise.resolve(errorResponse(SystemError.validation("Field 'role' is required")))
          }
        }
      )
      ->Promise.catch(_error =>
        Promise.resolve(errorResponse(SystemError.validation("Request body must be valid JSON")))
      )
    }
  }
  ->Promise.catch(error => {
    Js.log2("Create invitation controller unexpected error", error)
    Promise.resolve(errorResponse(SystemError.internal("Unable to create invitation")))
  })
}

@genType
let postJs = post
