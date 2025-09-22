module Dict = RescriptCore.Dict
module JSON = RescriptCore.JSON
module String = RescriptCore.String
module Promise = RescriptCore.Promise

let decodeStringField = (dict, key) =>
  switch Dict.get(dict, key) {
  | Some(value) => JSON.Decode.string(value)
  | None => None
  }

let decodeOptionalStringField = (dict, key) =>
  switch Dict.get(dict, key) {
  | None => Ok(None)
  | Some(value) =>
      switch JSON.Decode.string(value) {
      | Some(str) => Ok(Some(str))
      | None => Error("Field '" ++ key ++ "' must be a string")
      }
  }

let parseRegistrationRequest = (json: JSON.t): result<UserResource.registrationRequest, string> =>
  switch JSON.Decode.object(json) {
  | None => Error("Request body must be a JSON object")
  | Some(dict) =>
      let maybeEmail = decodeStringField(dict, "email")
      let maybeUsername = decodeStringField(dict, "username")
      let maybePassword = decodeStringField(dict, "password")
      let maybeOrgName = decodeStringField(dict, "initialOrganizationName")
      let displayNameResult = decodeOptionalStringField(dict, "displayName")
      let confirmPasswordResult = decodeOptionalStringField(dict, "confirmPassword")

      switch (maybeEmail, maybeUsername, maybePassword, maybeOrgName, displayNameResult, confirmPasswordResult) {
      | (Some(email), Some(username), Some(password), Some(orgName), Ok(displayName), Ok(confirmPassword)) =>
          Ok({
            email,
            username,
            displayName,
            password,
            confirmPassword,
            initialOrganizationName: orgName,
          })
      | (None, _, _, _, _, _) => Error("Field 'email' must be a string")
      | (_, None, _, _, _, _) => Error("Field 'username' must be a string")
      | (_, _, None, _, _, _) => Error("Field 'password' must be a string")
      | (_, _, _, None, _, _) => Error("Field 'initialOrganizationName' must be a string")
      | (_, _, _, _, Error(message), _) => Error(message)
      | (_, _, _, _, _, Error(message)) => Error(message)
      }
  }

let validateRegistration = (req: UserResource.registrationRequest): result<UserResource.registrationRequest, string> => {
  let sanitized = UserResource.sanitizeRegistrationRequest(req)
  if sanitized.initialOrganizationName == "" {
    Error("Initial organization name is required")
  } else if sanitized.username == "" {
    Error("Username is required")
  } else if sanitized.email == "" {
    Error("Email is required")
  } else {
    Ok(sanitized)
  }
}

type dependencies = RegisterWithPassword.dependencies

type astroContext = {request: Fetch.Request.t}

type response = {
  status: int,
  body: JSON.t,
}

let makeResponse = (~status, body) => {status, body}

let errorMessage = (err: RegisterWithPassword.error): string =>
  switch err {
  | #InvalidEmail(emailError) =>
      switch emailError {
      | #InvalidEmail(original) => "Invalid email: " ++ original
      }
  | #PasswordTooShort => "Password must be at least 8 characters long"
  | #PasswordsDoNotMatch => "Passwords do not match"
  | #InvalidName(original) => "Organization name is invalid: " ++ original
  | #InvalidShortCode(original) => "Unable to derive shortcode from name: " ++ original
  }

let unexpectedError = UserResource.encodeError("Unable to register user")

let post = (deps: dependencies, ctx: astroContext): Promise.t<response> => {
  let initial = Fetch.Request.json(ctx.request)
  let handled =
    Promise.then(initial, json =>
      switch parseRegistrationRequest(json) {
      | Error(message) =>
          Promise.resolve(makeResponse(~status=400, UserResource.encodeError(message)))
      | Ok(parsed) =>
          switch validateRegistration(parsed) {
          | Error(message) =>
              Promise.resolve(makeResponse(~status=400, UserResource.encodeError(message)))
          | Ok(validRequest) =>
              let command = UserResource.commandOfRegistrationRequest(validRequest)
              RegisterWithPassword.execute(deps, command)
              ->Promise.thenResolve(result =>
                  switch result {
                  | Ok(registeredUser) =>
                      makeResponse(~status=201, UserResource.encodeRegisteredUser(registeredUser))
                  | Error(err) =>
                      makeResponse(~status=400, UserResource.encodeError(errorMessage(err)))
                  }
                )
          }
      }
    )
  Promise.catch(handled, _ => Promise.resolve(makeResponse(~status=500, unexpectedError)))
}

let defaultDependencies: dependencies = {
  hashPassword: password => PasswordHasher.hash(~password),
}

@genType
let postJs = post

@genType
let defaultDependenciesJs = defaultDependencies
