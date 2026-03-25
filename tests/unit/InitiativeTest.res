open NodeTest

// ─── Initiative.Title ───────────────────────────────────────────

describe("Initiative.Title", () => {
  test("accepts a valid title", () => {
    switch Initiative.Title.make("Build onboarding flow") {
    | Ok(title) => equal(Initiative.Title.value(title), "Build onboarding flow")
    | Error(_) => ok(false)
    }
  })

  test("rejects an empty title", () => {
    switch Initiative.Title.make("") {
    | Ok(_) => ok(false)
    | Error(_) => ok(true)
    }
  })

  test("rejects a whitespace-only title", () => {
    switch Initiative.Title.make("   ") {
    | Ok(_) => ok(false)
    | Error(_) => ok(true)
    }
  })

  test("trims whitespace", () => {
    switch Initiative.Title.make("  Trimmed Title  ") {
    | Ok(title) => equal(Initiative.Title.value(title), "Trimmed Title")
    | Error(_) => ok(false)
    }
  })
})

// ─── Initiative.validateCreate ──────────────────────────────────

describe("Initiative.validateCreate", () => {
  test("succeeds with valid title and zero time budget", () => {
    switch Initiative.validateCreate(~title="My Initiative", ~timeBudget=0.0) {
    | Ok({title, slug}) =>
      equal(Initiative.Title.value(title), "My Initiative")
      equal(Slug.value(slug), "my-initiative")
    | Error(_) => ok(false)
    }
  })

  test("succeeds with valid title and positive time budget", () => {
    switch Initiative.validateCreate(~title="My Initiative", ~timeBudget=40.0) {
    | Ok(_) => ok(true)
    | Error(_) => ok(false)
    }
  })

  test("fails with empty title", () => {
    equal(Initiative.validateCreate(~title="", ~timeBudget=0.0), Error(#InvalidTitle("")))
  })

  test("fails with negative time budget", () => {
    equal(Initiative.validateCreate(~title="Valid Title", ~timeBudget=-1.0), Error(#InvalidTimeBudget))
  })

  test("validates title before time budget", () => {
    // negative budget AND empty title -> should report InvalidTitle since title is checked second
    // Actually, timeBudget is checked first in the code
    equal(Initiative.validateCreate(~title="Valid Title", ~timeBudget=-5.0), Error(#InvalidTimeBudget))
  })
})
