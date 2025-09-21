module Dict = RescriptCore.Dict
module JSON = RescriptCore.JSON
module String = RescriptCore.String
module Promise = RescriptCore.Promise
module Fetch = Fetch

let decodeStringField = (dict, key) =>
  switch Dict.get(dict, key) {
  | Some(value) => JSON.Decode.string(value)
  | None => None
  }

let parseRequest = (json: JSON.t): result<OrganizationResource.request, string> =>
  switch JSON.Decode.object(json) {
  | None => Error("Request body must be a JSON object")
  | Some(dict) =>
      let maybeName = decodeStringField(dict, "name")
      let maybeOwner = decodeStringField(dict, "ownerId")
      switch (maybeName, maybeOwner) {
      | (Some(name), Some(ownerId)) =>
          let trimmed = String.trim(name)
          if trimmed == "" {
            Error("Organization name is required")
          } else {
            Ok({name: trimmed, ownerId})
          }
      | (None, _) => Error("Field 'name' must be a string")
      | (_, None) => Error("Field 'ownerId' must be a string")
      }
  }

let commandOfRequest = ({name, ownerId}: OrganizationResource.request): CreateOrganization.command => {
  name,
  ownerId,
}

type astroContext = {request: Fetch.Request.t}

type response = {
  status: int,
  body: JSON.t,
}

let makeResponse = (~status, body) => {status, body}

let unexpectedError = OrganizationResource.encodeError("Unable to create organization")

let post = (ctx: astroContext): Promise.t<response> => {
  let initial = Fetch.Request.json(ctx.request)
  let handled =
    Promise.then(initial, json =>
      switch parseRequest(json) {
      | Ok(parsed) =>
          let command = commandOfRequest(parsed)
          switch CreateOrganization.execute(command) {
          | Ok(org) =>
              Promise.resolve(makeResponse(~status=201, OrganizationResource.encodeOrganization(org)))
          | Error(err) =>
              Promise.resolve(
                makeResponse(~status=400, OrganizationResource.encodeError(CreateOrganization.errorMessage(err))),
              )
          }
      | Error(message) =>
          Promise.resolve(makeResponse(~status=400, OrganizationResource.encodeError(message)))
      }
    )
  Promise.catch(handled, _ => Promise.resolve(makeResponse(~status=500, unexpectedError)))
}

@genType
let postJs = post
