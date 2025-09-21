type t
type error = [#InvalidUuid(string) | #NotV7(string)]

@genType let gen: unit => t
@genType let ofString: string => result<t, error>
@genType let ofStringUnsafe: string => t

@genType let value: t => string
let equal: (t, t) => bool

let encode: t => Js.Json.t
let decode: Js.Json.t => option<t>
