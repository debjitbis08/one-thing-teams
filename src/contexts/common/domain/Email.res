module Spec = {
  type raw = string
  type error = [#InvalidEmail(string)]
  let normalize = value => value->String.trim->String.toLowerCase
  let validate = value => RegExp.test(%re("/^[^\s@]+@[^\s@]+\.[^\s@]+$/"), value)
  let show = value => value
  let eq = (a, b) => a == b
  let invalidError = value => #InvalidEmail(value)
}

module Impl = ValueObject.Make(Spec)

type t = Impl.t

type error = Spec.error

let make = Impl.make

let unsafeMake = Impl.unsafeMake

let value = Impl.value

let equal = Impl.equal

let toString = Impl.toString
