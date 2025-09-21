/* GlobalUniqueId.res */
@bs.module("uuid")
external uuidv7: unit => string = "v7"
@bs.module("uuid")
external validateUUID: string => bool = "validate"

type t<'tag> = string
type baseError = [#InvalidGlobalUniqueId(string)]

let normalize = s => s->Js.String2.trim
let generate = (): t<'a> => uuidv7()
let value = (id: t<'a>) => id
let equal = (a: t<'a>, b: t<'a>) => a == b

let fromStringBase = (s: string): result<t<'a>, baseError> => {
  let v = normalize(s)
  if validateUUID(v) { Ok(v) } else { Error(#InvalidGlobalUniqueId(s)) }
}

let fromStringUnsafeBase = (s: string): t<'a> =>
  switch fromStringBase(s) {
  | Ok(id) => id
  | Error(#InvalidGlobalUniqueId(orig)) =>
      Js.Exn.raiseError("Invalid GlobalUniqueId: " ++ orig)
  }

let makeBase = (~id: option<string>=?): t<'a> =>
  switch id {
  | Some(v) => fromStringUnsafeBase(v)
  | None => generate()
  }

/* ---- functor to brand type + specialize error ---- */

module type SPEC = {
  type tag
  type error                 // e.g. [#InvalidUserId(string)]
  let label: string          // for unsafe error messages
  let invalid: string => error
}

module type S = {
  type t
  type error
  let generate: unit => t
  let value: t => string
  let equal: (t, t) => bool
  let fromString: string => result<t, error>
  let fromStringUnsafe: string => t
  let make: (~id: string=?, unit) => t
}

module Make = (X: SPEC): (S with type t = t<X.tag>) => {
  type t = t<X.tag>
  type error = X.error

  let generate = generate
  let value = value
  let equal = equal

  let fromString = (s: string): result<t, error> =>
    switch fromStringBase(s) {
    | Ok(id) => Ok(id)
    | Error(#InvalidGlobalUniqueId(orig)) => Error(X.invalid(orig))
    }

  let fromStringUnsafe = (s: string): t =>
    switch fromString(s) {
    | Ok(id) => id
    | Error(_) => Js.Exn.raiseError("Invalid " ++ X.label ++ ": " ++ s)
    }

  let make = (~id=?, ()) =>
    switch id {
    | Some(v) => fromStringUnsafe(v)
    | None => generate()
    }
}
