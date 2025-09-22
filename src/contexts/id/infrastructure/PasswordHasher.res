module Promise = RescriptCore.Promise

module Argon2 = {
  @module("argon2") external hashRaw: string => Promise.t<string> = "hash"
}

let hash = (~password: string): Promise.t<string> => Argon2.hashRaw(password)
