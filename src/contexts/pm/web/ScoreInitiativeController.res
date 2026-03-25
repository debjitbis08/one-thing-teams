module Dict = RescriptCore.Dict
module JSON = RescriptCore.JSON
module Promise = RescriptCore.Promise
module Encode = RescriptCore.JSON.Encode

type session = ScoreInitiative.session

type dependencies = {
  appendEvent: ScoreInitiative.scoredEvent => Promise.t<unit>,
  loadAggregate: string => Promise.t<option<ScoreInitiative.aggregateData>>,
  now: unit => float,
}

type astroContext = {
  request: Fetch.Request.t,
  session: option<session>,
  initiativeId: string,
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

let decodeBoolField = (dict, key) =>
  switch Dict.get(dict, key) {
  | Some(value) => JSON.Decode.bool(value)
  | None => None
  }

let decodeFloatField = (dict, key) =>
  switch Dict.get(dict, key) {
  | Some(value) => JSON.Decode.float(value)
  | None => None
  }

let decodeScoreNote = (dict, key): option<ScoreInitiative.scoreNote> =>
  switch Dict.get(dict, key) {
  | Some(value) =>
    switch JSON.Decode.object(value) {
    | None => None
    | Some(noteDict) =>
      switch Dict.get(noteDict, "value") {
      | Some(v) =>
        switch JSON.Decode.float(v) {
        | Some(f) =>
          let note = switch decodeStringField(noteDict, "note") {
          | Some(s) if String.trim(s) != "" => Some(s)
          | _ => None
          }
          Some({ScoreInitiative.value: Belt.Float.toInt(f), note})
        | None => None
        }
      | None => None
      }
    }
  | None => None
  }

let makeResponse = (~status, body) => {status, body}

let errorResponse = error => makeResponse(~status=SystemError.httpStatus(error), SystemError.encode(error))

let encodeSuccess = () => {
  let dict = Dict.make()
  dict->Dict.set("success", Encode.bool(true))
  Encode.object(dict)
}

let put = (deps: dependencies, ctx: astroContext): Promise.t<response> => {
  switch ctx.session {
  | None => Promise.resolve(errorResponse(SystemError.unauthorized("Unauthorized")))
  | Some(session) =>
    Fetch.Request.json(ctx.request)
    ->Promise.then(json =>
      switch JSON.Decode.object(json) {
      | None => Promise.resolve(errorResponse(SystemError.validation("Request body must be a JSON object")))
      | Some(dict) =>
        switch decodeStringField(dict, "scoreType") {
        | None =>
          Promise.resolve(errorResponse(SystemError.validation("Field 'scoreType' is required")))
        | Some(scoreType) =>
          let command: ScoreInitiative.command = {
            session,
            initiativeId: ctx.initiativeId,
            scoreType,
            userValue: decodeScoreNote(dict, "userValue"),
            timeCriticality: decodeScoreNote(dict, "timeCriticality"),
            riskReduction: decodeScoreNote(dict, "riskReduction"),
            effort: decodeScoreNote(dict, "effort"),
            isCore: decodeBoolField(dict, "isCore"),
            contributionCount: decodeFloatField(dict, "contributionCount"),
          }
          let appDeps: ScoreInitiative.dependencies = {
            now: deps.now,
            loadAggregate: deps.loadAggregate,
            appendEvent: deps.appendEvent,
          }
          ScoreInitiative.execute(appDeps, command)
          ->Promise.then(result =>
            switch result {
            | Ok(_) => Promise.resolve(makeResponse(~status=200, encodeSuccess()))
            | Error(#Forbidden) =>
              Promise.resolve(errorResponse(SystemError.forbidden("Forbidden")))
            | Error(#InitiativeNotFound) =>
              Promise.resolve(errorResponse(SystemError.notFound("Initiative not found")))
            | Error(#InvalidScoreType) =>
              Promise.resolve(errorResponse(SystemError.validation("scoreType must be 'proxy' or 'break_even'")))
            | Error(#MissingProxyFields) =>
              Promise.resolve(errorResponse(SystemError.validation("Proxy scoring requires userValue, timeCriticality, riskReduction, and effort")))
            | Error(#MissingBreakEvenFields) =>
              Promise.resolve(errorResponse(SystemError.validation("Break-even scoring requires contributionCount and effort")))
            | Error(#InvalidFibonacciValue(v)) =>
              Promise.resolve(errorResponse(SystemError.validation("Invalid Fibonacci scale value: " ++ Belt.Int.toString(v))))
            }
          )
        }
      }
    )
    ->Promise.catch(_error =>
      Promise.resolve(errorResponse(SystemError.validation("Request body must be valid JSON")))
    )
  }
  ->Promise.catch(error => {
    Js.log2("Score initiative controller unexpected error", error)
    Promise.resolve(errorResponse(SystemError.internal("Unable to score initiative")))
  })
}

@genType
let putJs = put
