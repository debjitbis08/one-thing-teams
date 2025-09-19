module type Spec = {
  type raw
  type error
  let normalize: raw => raw
  let validate: raw => bool
  let show: raw => string
  let eq: (raw, raw) => bool
  let invalidError: raw => error
}

module Make: (S: Spec) => {
  type t
  type error = S.error
  let make: S.raw => result<t, error>
  let unsafeMake: S.raw => t
  let value: t => S.raw
  let equal: (t, t) => bool
  let toString: t => string
}
