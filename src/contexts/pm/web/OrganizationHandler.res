type astroContext = {request: Fetch.Request.t}

type response = {
  status: int,
  body: RescriptCore.JSON.t,
}

let makeResponse = (~status, body) => {
  status,
  body,
}

let post = (ctx: astroContext): RescriptCore.Promise.t<response> =>
  (Fetch.Request.json(ctx.request)->RescriptCore.Promise.then((. json) =>
        switch OrganizationResource.parseRequest(json) {
        | Ok(parsed) =>
            let command = OrganizationResource.commandOfRequest(parsed)
            switch CreateOrganization.execute(command) {
            | Ok(org) =>
                RescriptCore.Promise.resolve(makeResponse(~status=201, OrganizationResource.encodeOrganization(org)))
            | Error(err) =>
                RescriptCore.Promise.resolve(
                  makeResponse(~status=400, OrganizationResource.encodeError(CreateOrganization.errorMessage(err))),
                )
            }
        | Error(message) =>
            RescriptCore.Promise.resolve(makeResponse(~status=400, OrganizationResource.encodeError(message)))
        }
     ))
  ->RescriptCore.Promise.catch((. _error) =>
        RescriptCore.Promise.resolve(makeResponse(~status=500, OrganizationResource.encodeError("Unable to create organization")))
     )

@genType
type responseJs = response

@genType
let postJs = post
