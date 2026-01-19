module Dict = RescriptCore.Dict
module Encode = RescriptCore.JSON.Encode

@genType
type category = [
  | #Unauthorized
  | #Forbidden
  | #NotFound
  | #Validation
  | #Conflict
  | #Internal
]

@genType
type t = {
  category: category,
  message: string,
}

let make = (~category, ~message) => {category, message}

let httpStatus = error =>
  switch error.category {
  | #Unauthorized => 401
  | #Forbidden => 403
  | #NotFound => 404
  | #Validation => 400
  | #Conflict => 409
  | #Internal => 500
  }

let encode = error => {
  let dict = Dict.make()
  dict->Dict.set("error", Encode.string(error.message))
  Encode.object(dict)
}

let forbidden = message => make(~category=#Forbidden, ~message=message)
let unauthorized = message => make(~category=#Unauthorized, ~message=message)
let notFound = message => make(~category=#NotFound, ~message=message)
let validation = message => make(~category=#Validation, ~message=message)
let conflict = message => make(~category=#Conflict, ~message=message)
let internal = message => make(~category=#Internal, ~message=message)
