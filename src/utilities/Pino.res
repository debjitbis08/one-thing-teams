/* type alias for the opaque JS logger object */
type t

/* bind the default export function (pino(...)) */
@module("pino")
external make: Js.t<'opts> => t = "default"

/* bind methods on logger using @send */
@send external info: (t, {}, string) => unit = "info"
@send external infoObj: (t, Js.Json.t) => unit = "info" /* object overload */
@send external error: (t, {}, string) => unit = "error"
@send external child: (t, Js.t<'opts>) => t = "child"
