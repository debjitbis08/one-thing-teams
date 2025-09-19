let allowedValues = [1, 2, 3, 5, 8, 13, 21, 34, 55, 89]

module Spec = {
  type raw = int
  type error = [#NotFibonacci(int)]
  let normalize = value => value
  let validate = value => RescriptCore.Array.includes(allowedValues, value)
  let show = value => Js.Int.toString(value)
  let eq = (a, b) => a == b
  let invalidError = value => #NotFibonacci(value)
}

module Impl = ValueObject.Make(Spec)

type t = Impl.t

type error = Spec.error

let make = Impl.make

let unsafeMake = Impl.unsafeMake

let value = Impl.value

let compare = (a: t, b: t) => RescriptCore.Int.compare(Impl.value(a), Impl.value(b))