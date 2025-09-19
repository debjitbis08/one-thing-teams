type t
type error = [#InvalidUuid(string) | #NotV7(string)]

let gen: unit => t
let ofString: string => result<t, error>
let ofStringUnsafe: string => t

let value: t => string
let equal: (t, t) => bool

let encode: t => Js.Json.t
let decode: Js.Json.t => option<t>
