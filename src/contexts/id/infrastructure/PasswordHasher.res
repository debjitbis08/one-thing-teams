module Argon2 = {
  @module("@node-rs/argon2") external hashRaw: string => Promise.t<string> = "hash"
  @module("@node-rs/argon2") external verifyRaw: (string, string) => Promise.t<bool> = "verify"
}

let hash = (~password: string): Promise.t<string> => Argon2.hashRaw(password)

let verify = (~hash: string, ~password: string): Promise.t<bool> => Argon2.verifyRaw(hash, password)
