module type Spec = {
  type raw
  type error
  let normalize: raw => raw
  let validate: raw => bool
  let show: raw => string
  let eq: (raw, raw) => bool
  let invalidError: raw => error
}

module Make = (S: Spec) => {
  type t = S.raw
  type error = S.error

  let make = (value: S.raw) => {
    let normalized = S.normalize(value)
    if S.validate(normalized) {
      Belt.Result.Ok(normalized)
    } else {
      Belt.Result.Error(S.invalidError(normalized))
    }
  }

  let unsafeMake = (value: S.raw) =>
    switch make(value) {
    | Belt.Result.Ok(vo) => vo
    | Belt.Result.Error(err) => Js.Exn.raiseError(S.show(value) ++ " is invalid")
    }

  let value = (vo: t) => vo

  let equal = (left: t, right: t) => S.eq(left, right)

  let toString = (vo: t) => S.show(vo)
}
