module Dict = RescriptCore.Dict
module JSON = RescriptCore.JSON
module String = RescriptCore.String
module Promise = RescriptCore.Promise
module Fetch = Fetch
module Array = Belt.Array
module Option = Belt.Option
module Encode = RescriptCore.JSON.Encode
module RenameOrganization = RenameOrganization

let hasAllowedRole = roles => roles->Array.some(role => role == "OWNER" || role == "ADMIN")

type session = RenameOrganization.session

type dependencies = {
  appendEvent: RenameOrganization.renameEvent => Promise.t<unit>,
  loadAggregate: string => Promise.t<option<RenameOrganization.aggregateData>>,
  now: unit => float,
}

type renameRequest = {
  organizationId: string,
  name: string,
}

type sanitizedRenameRequest = {
  organizationId: string,
  name: string,
}

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

let parseRenameRequest = (json: JSON.t): result<renameRequest, string> =>
  switch JSON.Decode.object(json) {
  | None => Error("Request body must be a JSON object")
  | Some(dict) =>
      let maybeId = decodeStringField(dict, "organizationId")
      let maybeName = decodeStringField(dict, "name")
      switch (maybeId, maybeName) {
      | (Some(organizationId), Some(name)) => Ok({organizationId, name})
      | (None, _) => Error("Field 'organizationId' must be a string")
      | (_, None) => Error("Field 'name' must be a string")
      }
  }

let sanitizeRenameRequest = (req: renameRequest): sanitizedRenameRequest => {
  let sanitizedId = req.organizationId->String.trim
  let sanitizedName = req.name->String.trim
  {organizationId: sanitizedId, name: sanitizedName}
}

let encodeSuccess = () => {
  let dict = Dict.make()
  dict->Dict.set("success", Encode.bool(true))
  Encode.object(dict)
}

let makeResponse = (~status, body) => {status, body}

let errorResponse = error => makeResponse(~status=SystemError.httpStatus(error), SystemError.encode(error))

let patch = (deps: dependencies, ctx: astroContext): Promise.t<response> => {
  switch ctx.session {
  | None =>
      Promise.resolve(
        errorResponse(SystemError.unauthorized("Unauthorized")),
      )
  | Some(session) =>
      if !hasAllowedRole(session.roles) {
        Promise.resolve(errorResponse(SystemError.forbidden("Forbidden")))
      } else {
        Fetch.Request.json(ctx.request)
        ->Promise.then(json =>
            switch parseRenameRequest(json) {
            | Error(message) => Promise.resolve(errorResponse(SystemError.validation(message)))
            | Ok(parsed) =>
                let sanitized = sanitizeRenameRequest(parsed)
                if sanitized.name == "" {
                  Promise.resolve(errorResponse(SystemError.validation("Organization name is required")))
                } else {
                  let command: RenameOrganization.command = {
                    session,
                    organizationId: sanitized.organizationId,
                    name: sanitized.name,
                  }
                  let appDeps: RenameOrganization.dependencies = {
                    now: deps.now,
                    loadAggregate: deps.loadAggregate,
                    appendEvent: deps.appendEvent,
                  }
                  RenameOrganization.execute(appDeps, command)
                  ->Promise.then(result =>
                      switch result {
                      | Ok(_) => Promise.resolve(makeResponse(~status=202, encodeSuccess()))
                      | Error(#Forbidden) => Promise.resolve(errorResponse(SystemError.forbidden("Forbidden")))
                      | Error(#OrganizationNotFound) =>
                          Promise.resolve(errorResponse(SystemError.notFound("Organization not found")))
                      | Error(#InvalidName(original)) =>
                          Promise.resolve(
                            errorResponse(
                              SystemError.validation("Organization name is invalid: " ++ original),
                            ),
                          )
                      | Error(#InvalidShortCode(original)) =>
                          Promise.resolve(
                            errorResponse(
                              SystemError.validation("Unable to derive shortcode from name: " ++ original),
                            ),
                          )
                      }
                    )
                }
            }
          )
        ->Promise.catch(_error =>
            Promise.resolve(errorResponse(SystemError.validation("Request body must be valid JSON")))
          )
      }
  }
  ->Promise.catch(error => {
      Js.log2("Rename organization controller unexpected error", error)
      Promise.resolve(
        errorResponse(SystemError.internal("Unable to rename organization")),
      )
    })
}

@genType
let patchJs = patch
