module Dict = RescriptCore.Dict
module JSON = RescriptCore.JSON
module Promise = RescriptCore.Promise
module Encode = RescriptCore.JSON.Encode

type session = CreateProduct.session

type dependencies = CreateProduct.dependencies

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

let decodeOptionalStringField = (dict, key) =>
  switch Dict.get(dict, key) {
  | Some(value) =>
    switch JSON.Decode.string(value) {
    | Some(s) if String.trim(s) != "" => Some(Some(s))
    | Some(_) => Some(None)
    | None => Some(None)
    }
  | None => Some(None)
  }

let makeResponse = (~status, body) => {status, body}

let errorResponse = error => makeResponse(~status=SystemError.httpStatus(error), SystemError.encode(error))

let encodeSuccess = (result: CreateProduct.createdResult) => {
  let dict = Dict.make()
  dict->Dict.set("productId", Encode.string(result.productId))
  dict->Dict.set("name", Encode.string(result.name))
  dict->Dict.set("shortCode", Encode.string(result.shortCode))
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
        switch (decodeStringField(dict, "name"), decodeOptionalStringField(dict, "description")) {
        | (Some(name), Some(description)) =>
          let command: CreateProduct.command = {
            session,
            name,
            description,
          }
          CreateProduct.execute(deps, command)
          ->Promise.then(result =>
            switch result {
            | Ok(created) => Promise.resolve(makeResponse(~status=201, encodeSuccess(created)))
            | Error(#Forbidden) => Promise.resolve(errorResponse(SystemError.forbidden("Forbidden")))
            | Error(#InvalidName(n)) =>
              Promise.resolve(errorResponse(SystemError.validation("Invalid product name: " ++ n)))
            | Error(#InvalidShortCode(s)) =>
              Promise.resolve(errorResponse(SystemError.validation("Invalid short code: " ++ s)))
            }
          )
        | (None, _) => Promise.resolve(errorResponse(SystemError.validation("Field 'name' is required")))
        | (_, None) => Promise.resolve(errorResponse(SystemError.validation("Invalid 'description' field")))
        }
      }
    )
    ->Promise.catch(_error =>
      Promise.resolve(errorResponse(SystemError.validation("Request body must be valid JSON")))
    )
  }
  ->Promise.catch(error => {
    Js.log2("Create product controller unexpected error", error)
    Promise.resolve(errorResponse(SystemError.internal("Unable to create product")))
  })
}

@genType
let postJs = post
