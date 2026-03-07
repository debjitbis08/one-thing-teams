module Title = ConstrainedString.Make({
  let minLength = 1
  let maxLength = Some(200)
  let label = "Initiative title"
})

type createError = [
  | #InvalidTitle(string)
  | #InvalidTimeBudget
]

let validateCreate = (~title: string, ~timeBudget: float): result<Title.t, createError> =>
  if timeBudget < 0.0 {
    Error(#InvalidTimeBudget)
  } else {
    switch Title.make(title) {
    | Error(_) => Error(#InvalidTitle(title))
    | Ok(validTitle) => Ok(validTitle)
    }
  }
