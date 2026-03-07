module Name = ConstrainedString.Make({
  let minLength = 1
  let maxLength = Some(100)
  let label = "Product name"
})

type createError = [
  | #InvalidName(string)
  | #InvalidShortCode(string)
]

let validateCreate = (~name: string, ~shortCode: string): result<(Name.t, ShortCode.t), createError> =>
  switch Name.make(name) {
  | Error(_) => Error(#InvalidName(name))
  | Ok(validName) =>
    switch ShortCode.make(shortCode) {
    | Error(_) => Error(#InvalidShortCode(shortCode))
    | Ok(validShortCode) => Ok((validName, validShortCode))
    }
  }
