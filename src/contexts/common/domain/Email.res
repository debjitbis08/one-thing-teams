module Spec = {
  type raw = string
  type error = [#InvalidEmail(string)]
  let normalize = value => value->Js.String2.trim->Js.String2.toLowerCase
  let validate = value => RescriptCore.RegExp.test(%re("/^[^\s@]+@[^\s@]+\.[^\s@]+$/"), value)
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
