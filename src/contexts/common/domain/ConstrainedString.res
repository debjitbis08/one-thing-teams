/* ConstrainedString.res */
module type Range = {
  let minLength: int       /* inclusive */
  let maxLength: option<int> /* None => unbounded */
  let label: string        /* used in unsafe error messages */
}

module Make = (Config: Range) => {
  module Spec = {
    type raw = string
    type error = [#InvalidString(string)]
    let normalize = (s) => Js.String2.trim(s)
    let length = Js.String2.length

    let validate = value => {
      let len = length(value)
      let atLeastMin = len >= Config.minLength
      let withinMax =
        switch Config.maxLength {
        | None => true
        | Some(max) => len <= max
        }
      atLeastMin && withinMax
    }

    let show = value => value
    let eq = (a, b) => a == b
    let invalidError = value => #InvalidString(value)
  }

  include ValueObject.Make(Spec)

  let unsafeMake = value =>
    switch make(value) {
    | Belt.Result.Ok(vo) => vo
    | Belt.Result.Error(_) =>
        Js.Exn.raiseError(Config.label ++ " must be between "
          ++ string_of_int(Config.minLength)
          ++ (switch Config.maxLength {
              | None => "+ chars"
              | Some(max) => " and " ++ string_of_int(max) ++ " chars"
             }))
    }
}
