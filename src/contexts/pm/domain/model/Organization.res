module Organization = {
  type error =
    | InvalidName(string)
    | InvalidShortCode(string)

  @genType
  let create = (~name: string, ()): result<Domain.organization, error> => {
    let trimmed = name->Js.String2.trim

    switch Domain.OrganizationName.make(trimmed) {
    | Belt.Result.Error(nameErr) =>
        Belt.Result.Error(
          switch nameErr {
          | #InvalidString(original) => InvalidName(original)
          }
        )
    | Belt.Result.Ok(validName) =>
        switch ShortCode.make(trimmed) {
        | Belt.Result.Ok(shortCode) =>
            Belt.Result.Ok({
              organizationId: Domain.OrganizationId(UUIDv7.gen()),
              name: validName,
              shortCode,
            })
        | Belt.Result.Error(codeErr) =>
            Belt.Result.Error(
              switch codeErr {
              | #InvalidShortCode(original) => InvalidShortCode(original)
              }
            )
        }
    }
  }
}
