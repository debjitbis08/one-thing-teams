module TokenBucketRateLimit: {
  type t
  let make: (~max: int, ~refillIntervalSeconds: int) => t
  let check: (t, string, int) => bool
  let consume: (t, string, int) => bool
}

module BasicRateLimit: {
  type t
  let make: (~max: int, ~windowSizeInSeconds: int) => t
  let check: (t, string, int) => bool
  let consume: (t, string, int) => bool
  let reset: (t, string) => unit
}

module Counter: {
  type t
  let make: (~max: int) => t
  let increment: (t, string) => bool
  let reset: (t, string) => unit
}
