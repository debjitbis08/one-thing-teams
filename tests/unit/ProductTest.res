open NodeTest

// ─── Product.Name ───────────────────────────────────────────────

describe("Product.Name", () => {
  test("accepts a valid product name", () => {
    switch Product.Name.make("My Product") {
    | Ok(name) => equal(Product.Name.value(name), "My Product")
    | Error(_) => ok(false)
    }
  })

  test("rejects an empty name", () => {
    switch Product.Name.make("") {
    | Ok(_) => ok(false)
    | Error(_) => ok(true)
    }
  })

  test("rejects a whitespace-only name", () => {
    switch Product.Name.make("   ") {
    | Ok(_) => ok(false)
    | Error(_) => ok(true)
    }
  })

  test("trims whitespace", () => {
    switch Product.Name.make("  Trimmed  ") {
    | Ok(name) => equal(Product.Name.value(name), "Trimmed")
    | Error(_) => ok(false)
    }
  })
})

// ─── Product.validateCreate ─────────────────────────────────────

describe("Product.validateCreate", () => {
  test("succeeds with valid name and short code", () => {
    switch Product.validateCreate(~name="Test Product", ~shortCode="TP") {
    | Ok((name, shortCode)) =>
      equal(Product.Name.value(name), "Test Product")
      equal(ShortCode.value(shortCode), "TP")
    | Error(_) => ok(false)
    }
  })

  test("fails with empty name", () => {
    equal(Product.validateCreate(~name="", ~shortCode="TP"), Error(#InvalidName("")))
  })

  test("fails with invalid short code", () => {
    switch Product.validateCreate(~name="Valid Name", ~shortCode="") {
    | Error(#InvalidShortCode(_)) => ok(true)
    | _ => ok(false)
    }
  })

  test("normalizes short code input", () => {
    let normalized = ShortCode.Spec.normalize("My Product")
    switch Product.validateCreate(~name="My Product", ~shortCode=normalized) {
    | Ok((_, shortCode)) =>
      let v = ShortCode.value(shortCode)
      ok(Js.Re.test_(%re("/^[A-Z]{2,3}$/"), v))
    | Error(_) => ok(false)
    }
  })
})
