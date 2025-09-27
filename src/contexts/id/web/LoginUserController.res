module Array = Belt.Array
module List = Belt.List

module SessionResource = SessionResource

@module("../infrastructure/SessionTokenService")
external issueSessionTokens: SessionResource.sessionTokenInput => Promise.t<SessionResource.issuedTokens> = "issueSessionTokens"

let loginRateLimiter = RateLimit.TokenBucketRateLimit.make(~max=5, ~refillIntervalSeconds=30)

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

let sanitizeHeaderValue = value => {
  let trimmed = value->String.trim
  if trimmed == "" {
    None
  } else {
    Some(trimmed)
  }
}

let headerValue = (headers, name) =>
  switch Fetch.Headers.get(headers, name) {
  | Some(value) => sanitizeHeaderValue(value)
  | None => None
  }

let forwardedForIp = headers =>
  switch Fetch.Headers.get(headers, "x-forwarded-for") {
  | None => None
  | Some(value) =>
      let parts = value->String.split(",")
      switch Array.get(parts, 0) {
      | None => None
      | Some(first) => sanitizeHeaderValue(first)
      }
  }

let rec firstSome = items =>
  switch items {
  | list{} => None
  | list{head, ...tail} =>
      switch head {
      | Some(value) => Some(value)
      | None => firstSome(tail)
      }
  }

let clientIp = request => {
  let headers = Fetch.Request.headers(request)
  switch firstSome(list{
    headerValue(headers, "cf-connecting-ip"),
    forwardedForIp(headers),
    headerValue(headers, "x-real-ip"),
  }) {
  | Some(ip) => ip
  | None => "unknown"
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
    Promise.then(initial, json => {
      switch parseLoginRequest(json) {
      | Error(message) => Promise.resolve(makeResponse(~status=400, SessionResource.encodeError(message)))
      | Ok(parsed) =>
          switch validateLogin(parsed) {
          | Error(message) => Promise.resolve(makeResponse(~status=400, SessionResource.encodeError(message)))
          | Ok(validRequest) =>
              let command = SessionResource.commandOfLoginRequest(validRequest)
              let ip = clientIp(ctx.request)
              let key = ip ++ ":" ++ validRequest.usernameOrEmail->String.toLowerCase
              if !RateLimit.TokenBucketRateLimit.consume(loginRateLimiter, key, 1) {
                Promise.resolve(
                  makeResponse(~status=429, SessionResource.encodeError("Too many login attempts. Please try again later."))
                )
              } else {
                IdentityWorkflows.Login.execute(command)
                ->Promise.then(result => {
                    switch result {
                    | Ok(session) =>
                        let tokenInput = SessionResource.sessionTokenInputOfUserSession(session)
                        Js.log2("Issuing session tokens for", tokenInput)
                        issueSessionTokens(tokenInput)
                        ->Promise.then(tokens => {
                            Promise.resolve(
                              makeResponse(~status=200, SessionResource.encodeLoginSuccess(~session, ~tokens))
                            )
                          })
                    | Error(err) => Promise.resolve(errorResponse(err))
                    }
                })
              }
          }
      }
  })
  Promise.catch(handled, err => {
    Console.log2("Login controller unexpected error", err)
    Promise.resolve(makeResponse(~status=500, unexpectedError))
  })
}

@genType
let postJs = post
