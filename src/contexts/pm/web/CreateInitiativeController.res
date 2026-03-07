module Dict = RescriptCore.Dict
module JSON = RescriptCore.JSON
module Promise = RescriptCore.Promise
module Encode = RescriptCore.JSON.Encode
module CreateInitiative = CreateInitiative

type session = CreateInitiative.session

type dependencies = CreateInitiative.dependencies

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

let decodeOptionalFloatField = (dict, key) =>
  switch Dict.get(dict, key) {
  | Some(value) => JSON.Decode.float(value)->Option.map(f => Some(f))
  | None => Some(None)
  }

let makeResponse = (~status, body) => {status, body}

let errorResponse = error => makeResponse(~status=SystemError.httpStatus(error), SystemError.encode(error))

let encodeSuccess = (result: CreateInitiative.createdResult) => {
  let dict = Dict.make()
  dict->Dict.set("initiativeId", Encode.string(result.initiativeId))
  dict->Dict.set("productId", Encode.string(result.productId))
  dict->Dict.set("title", Encode.string(result.title))
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
        switch (
          decodeStringField(dict, "productId"),
          decodeStringField(dict, "title"),
          decodeOptionalStringField(dict, "description"),
          decodeOptionalFloatField(dict, "timeBudget"),
          decodeOptionalStringField(dict, "chatRoomLink"),
        ) {
        | (Some(productId), Some(title), Some(description), Some(timeBudget), Some(chatRoomLink)) =>
          let command: CreateInitiative.command = {
            session,
            productId,
            title,
            description,
            timeBudget,
            chatRoomLink,
          }
          CreateInitiative.execute(deps, command)
          ->Promise.then(result =>
            switch result {
            | Ok(created) => Promise.resolve(makeResponse(~status=201, encodeSuccess(created)))
            | Error(#Forbidden) => Promise.resolve(errorResponse(SystemError.forbidden("Forbidden")))
            | Error(#InvalidTitle(t)) =>
              Promise.resolve(errorResponse(SystemError.validation("Invalid initiative title: " ++ t)))
            | Error(#InvalidTimeBudget) =>
              Promise.resolve(errorResponse(SystemError.validation("Time budget must be non-negative")))
            | Error(#ProductNotFound) =>
              Promise.resolve(errorResponse(SystemError.notFound("Product not found")))
            }
          )
        | (None, _, _, _, _) =>
          Promise.resolve(errorResponse(SystemError.validation("Field 'productId' is required")))
        | (_, None, _, _, _) =>
          Promise.resolve(errorResponse(SystemError.validation("Field 'title' is required")))
        | _ => Promise.resolve(errorResponse(SystemError.validation("Invalid request fields")))
        }
      }
    )
    ->Promise.catch(_error =>
      Promise.resolve(errorResponse(SystemError.validation("Request body must be valid JSON")))
    )
  }
  ->Promise.catch(error => {
    Js.log2("Create initiative controller unexpected error", error)
    Promise.resolve(errorResponse(SystemError.internal("Unable to create initiative")))
  })
}

@genType
let postJs = post
