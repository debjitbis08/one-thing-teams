module Promise = RescriptCore.Promise
module String = RescriptCore.String
module FetchJs = Fetch

module Global = {
  @val
  external fetch: string => RescriptCore.Promise.t<FetchJs.Response.t> = "fetch"
}

module NodeCrypto = {
  type hash

  @module("crypto")
  external createHash: string => hash = "createHash"

  @send external update: (hash, string) => hash = "update"
  @send external digestHex: (hash, string) => string = "digest"
}

let minLength = 8
let maxLength = 255
let hibpEndpoint = "https://api.pwnedpasswords.com/range/"

let isLengthValid = password => {
  let len = String.length(password)
  len >= minLength && len <= maxLength
}

let sha1Hex = password =>
  NodeCrypto.createHash("sha1")
  ->NodeCrypto.update(password)
  ->NodeCrypto.digestHex("hex")

let takePrefix = (str, count) => RescriptCore.String.slice(str, ~start=0, ~end=count)
let takeSuffix = (str, fromIndex) => RescriptCore.String.sliceToEnd(str, ~start=fromIndex)

let fetchRange = prefix => {
  let url = hibpEndpoint ++ prefix
  Global.fetch(url)
  ->Promise.then(response => FetchJs.Response.text(response))
}

let passwordCompromised = (~hashSuffix: string, ~responseBody: string) => {
  responseBody
  ->String.split("\n")
  ->Belt.Array.some(line => {
      let cleanedLine = line->String.trim
      if cleanedLine == "" {
        false
      } else {
        switch cleanedLine->String.split(":") {
        | [suffix, _count] => suffix->String.toLowerCase == hashSuffix
        | _ => false
        }
      }
    })
}

let verifyStrong = (password: string): Promise.t<bool> =>
  if !isLengthValid(password) {
    Promise.resolve(false)
  } else {
    let hashHex = sha1Hex(password)
    let prefix = hashHex->takePrefix(5)
    let suffix = hashHex->takeSuffix(5)

    fetchRange(prefix)
    ->Promise.then(result =>
        if passwordCompromised(~hashSuffix=suffix, ~responseBody=result) {
          Promise.resolve(false)
        } else {
          Promise.resolve(true)
        }
      )
    ->Promise.catch(_ => Promise.resolve(true))
  }
