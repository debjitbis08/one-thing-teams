module Title = ConstrainedString.Make({
  let minLength = 1
  let maxLength = Some(200)
  let label = "Initiative title"
})

type createError = [
  | #InvalidTitle(string)
  | #InvalidTimeBudget
  | #InvalidSlug(string)
]

type validated = {
  title: Title.t,
  slug: Slug.t,
}

let validateCreate = (~title: string, ~timeBudget: float): result<validated, createError> =>
  if timeBudget < 0.0 {
    Error(#InvalidTimeBudget)
  } else {
    switch Title.make(title) {
    | Error(_) => Error(#InvalidTitle(title))
    | Ok(validTitle) =>
      switch Slug.fromTitle(title) {
      | Error(#InvalidSlug(s)) => Error(#InvalidSlug(s))
      | Ok(slug) => Ok({title: validTitle, slug})
      }
    }
  }
