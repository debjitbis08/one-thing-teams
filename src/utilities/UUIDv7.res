@module("uuid") external v7: unit => string = "v7"
@module("uuid") external validate: string => bool = "validate"
@module("uuid") external version: string => int = "version"

type t = string
type error = [#InvalidUuid(string) | #NotV7(string)]

let norm = s => s->Js.String2.trim->Js.String2.toLowerCase

let isV7 = s =>
    validate(s) && version(s) == 7

let gen = (): t => v7()

let ofString = (s: string): result<t, error> => {
  let v = norm(s)
  if !validate(v) { Error(#InvalidUuid(s)) }
  else if !isV7(v) { Error(#NotV7(s)) }
  else  { Ok(v) }
}

let ofStringUnsafe = (s: string): t =>
  switch ofString(s) {
  | Ok(x) => x
  | Error(#InvalidUuid(orig)) => Js.Exn.raiseError("Invalid UUID: " ++ orig)
  | Error(#NotV7(orig)) => Js.Exn.raiseError("Not a UUIDv7: " ++ orig)
  }

let value = (x: t) => x
let equal = (a: t, b: t) => a == b

let encode = (x: t) => Js.Json.string(x)
let decode = j =>
  switch Js.Json.classify(j) {
  | Js.Json.JSONString(s) =>
      switch ofString(s) { | Ok(x) => Some(x) | _ => None }
  | _ => None
}
