module Spec = {
  type raw = string
  type error = [#InvalidShortCode(string)]

  let shortCodeRe = %re("/^[A-Z]{2,3}$/")

  let normalize = value => {
    let trimmed = value->Js.String2.trim
    if Js.Re.test_(shortCodeRe, trimmed) {
      trimmed
    } else {
      let cleaned =
        trimmed
        ->Js.String2.toUpperCase
        ->Js.String2.replaceByRe(%re("/[^A-Z]/g"), "")

      let collapse = word =>
        word
        ->Js.String2.toUpperCase
        ->Js.String2.replaceByRe(%re("/[^A-Z]/g"), "")
        ->Js.String2.replaceByRe(%re("/([AEIOUY])[AEIOUY]+/g"), "$1")
        ->Js.String2.replaceByRe(%re("/([BCDFGHJKLMNPQRSTVWXZ])[BCDFGHJKLMNPQRSTVWXZ]+/g"), "$1")

      switch Js.String2.length(cleaned) {
      | 0 => ""
      | 1 => cleaned ++ "X"
      | 2 => cleaned
      | _ => collapse(cleaned)->Js.String2.slice(~from=0, ~to_=2)
      }
    }
  }

  let validate = value => Js.Re.test_(shortCodeRe, value)
  let show = value => value
  let eq = (a, b) => a == b
  let invalidError = value => #InvalidShortCode(value)
}

module Impl = ValueObject.Make(Spec)

type t = Impl.t

@genType
type error = Spec.error

let make = Impl.make

let unsafeMake = Impl.unsafeMake

@genType
let value = Impl.value

let equal = Impl.equal

let toString = Impl.toString
