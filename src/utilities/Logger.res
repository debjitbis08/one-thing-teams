open Pino
@module("../config/env.ts")
external env: {..} = "env"

let logger = make({
  "redact": ["DATABASE_URL"],
  "level": env["LOG_LEVEL"],
  "transport": {
    "target": "pino-pretty",
  }
})

let blank = Object.make()

/* helper to log object messages */
let infoObj = (o: JSON.t) => infoObj(logger, o)
let info = (msg, ~data=blank) => info(logger, data, msg)
let error = (msg, ~data=blank) => error(logger, data, msg)
