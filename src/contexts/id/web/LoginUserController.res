module Dict = RescriptCore.Dict
module JSON = RescriptCore.JSON
module String = RescriptCore.String
module Promise = RescriptCore.Promise
module Fetch = Fetch

module SessionResource = SessionResource

@module("../infrastructure/SessionTokenService")
external issueSessionTokens: SessionResource.sessionTokenInput => Promise.t<SessionResource.issuedTokens> = "issueSessionTokens"

let decodeStringField = (dict, key) =>
  switch Dict.get(dict, key) {
  | Some(value) => JSON.Decode.string(value)
  | None => None
  }

let parseLoginRequest = (json: JSON.t): result<SessionResource.loginRequest, string> =>
  switch JSON.Decode.object(json) {
  | None => Error("Request body must be a JSON object")
  | Some(dict) =>
      let maybeIdentifier = decodeStringField(dict, "usernameOrEmail")
      let maybePassword = decodeStringField(dict, "password")
      switch (maybeIdentifier, maybePassword) {
      | (Some(usernameOrEmail), Some(password)) => Ok({usernameOrEmail, password})
      | (None, _) => Error("Field 'usernameOrEmail' must be a string")
      | (_, None) => Error("Field 'password' must be a string")
      }
  }

let validateLogin = (req: SessionResource.loginRequest): result<SessionResource.loginRequest, string> => {
  let sanitized = SessionResource.sanitizeLoginRequest(req)
  if sanitized.usernameOrEmail == "" {
    Error("Username or email is required")
  } else if sanitized.password == "" {
    Error("Password is required")
  } else {
    Ok(sanitized)
  }
}

type astroContext = {request: Fetch.Request.t}

type response = {
  status: int,
  body: JSON.t,
}

let makeResponse = (~status, body) => {status, body}

let errorResponse = err =>
  switch err {
  | #UserNotFound => makeResponse(~status=404, SessionResource.encodeError("User not found"))
  | #InvalidCredentials => makeResponse(~status=401, SessionResource.encodeError("Invalid username or password"))
  }

let unexpectedError = SessionResource.encodeError("Unable to login user")

let post = (ctx: astroContext): Promise.t<response> => {
  let initial = Fetch.Request.json(ctx.request)
  let handled =
    Promise.then(initial, json =>
      switch parseLoginRequest(json) {
      | Error(message) => Promise.resolve(makeResponse(~status=400, SessionResource.encodeError(message)))
      | Ok(parsed) =>
          switch validateLogin(parsed) {
          | Error(message) => Promise.resolve(makeResponse(~status=400, SessionResource.encodeError(message)))
          | Ok(validRequest) =>
              let command = SessionResource.commandOfLoginRequest(validRequest)
              IdentityWorkflows.Login.execute(command)
              ->Promise.then(result =>
                  switch result {
                  | Ok(session) =>
                      let tokenInput = SessionResource.sessionTokenInputOfUserSession(session)
                      issueSessionTokens(tokenInput)
                      ->Promise.then(tokens =>
                          Promise.resolve(
                            makeResponse(~status=200, SessionResource.encodeLoginSuccess(~session, ~tokens))
                          )
                        )
                  | Error(err) => Promise.resolve(errorResponse(err))
                  }
                )
          }
      }
    )
  Promise.catch(handled, _ => Promise.resolve(makeResponse(~status=500, unexpectedError)))
}

@genType
let postJs = post
