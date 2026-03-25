module Spec = {
  type raw = string
  type error = [#InvalidSlug(string)]

  let slugRe = %re("/^[a-z0-9]+(-[a-z0-9]+)*$/")

  let normalize = value => {
    value
    ->Js.String2.trim
    ->Js.String2.toLowerCase
    ->Js.String2.replaceByRe(%re("/[^a-z0-9]+/g"), "-")
    ->Js.String2.replaceByRe(%re("/^-+|-+$/g"), "")
  }

  let validate = value =>
    Js.String2.length(value) >= 1 &&
      Js.String2.length(value) <= 200 &&
      Js.Re.test_(slugRe, value)

  let show = value => value
  let eq = (a, b) => a == b
  let invalidError = value => #InvalidSlug(value)
}

module Impl = ValueObject.Make(Spec)

type t = Impl.t

@genType
type error = Spec.error

@genType
let fromTitle = Impl.make

@genType
let make = Impl.make

@genType
let value = Impl.value

let equal = Impl.equal

let toString = Impl.toString

@genType
let withSuffix = (slug: t, suffix: int): t => {
  let base = value(slug)
  Impl.unsafeMake(base ++ "-" ++ Belt.Int.toString(suffix))
}
