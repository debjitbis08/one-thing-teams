open NodeTest

let invitationId = InvitationId.InvitationId(UUIDv7.gen())
let orgId = OrganizationId.OrganizationId(UUIDv7.gen())
let creatorId = UserId.UserId(UUIDv7.gen())
let accepterId = UserId.UserId(UUIDv7.gen())
let revokerId = UserId.UserId(UUIDv7.gen())

let now = 1_700_000_000_000.0
let futureExpiry = now +. Invitation.defaultExpirationMs
let pastExpiry = now -. 1000.0

let email = Email.unsafeMake("invitee@example.com")
let differentEmail = Email.unsafeMake("other@example.com")

let makePending = (~expiresAt=futureExpiry, ()) => {
  let inv: Invitation.t = {
    invitationId,
    organizationId: orgId,
    organizationName: "Test Org",
    email,
    role: EDITOR,
    tokenHash: "abc123",
    status: Pending,
    expiresAt,
    createdBy: creatorId,
    createdAt: now -. 1000.0,
    acceptedBy: None,
    acceptedAt: None,
    revokedBy: None,
    revokedAt: None,
  }
  inv
}

let makeAccepted = () => {
  ...makePending(),
  status: Accepted,
  acceptedBy: Some(accepterId),
  acceptedAt: Some(now -. 500.0),
}

let makeRevoked = () => {
  ...makePending(),
  status: Revoked,
  revokedBy: Some(revokerId),
  revokedAt: Some(now -. 500.0),
}

// ─── effectiveStatus ────────────────────────────────────────────

describe("effectiveStatus", () => {
  test("returns Pending for a non-expired pending invitation", () => {
    let inv = makePending()
    equal(Invitation.effectiveStatus(~invitation=inv, ~now), Invitation.Pending)
  })

  test("returns Revoked for an expired pending invitation", () => {
    let inv = makePending(~expiresAt=pastExpiry, ())
    equal(Invitation.effectiveStatus(~invitation=inv, ~now), Invitation.Revoked)
  })

  test("returns Accepted for an accepted invitation regardless of expiry", () => {
    let inv = {...makeAccepted(), expiresAt: pastExpiry}
    equal(Invitation.effectiveStatus(~invitation=inv, ~now), Invitation.Accepted)
  })

  test("returns Revoked for a revoked invitation regardless of expiry", () => {
    let inv = makeRevoked()
    equal(Invitation.effectiveStatus(~invitation=inv, ~now), Invitation.Revoked)
  })
})

// ─── isExpired ──────────────────────────────────────────────────

describe("isExpired", () => {
  test("returns false for a non-expired pending invitation", () => {
    let inv = makePending()
    equal(Invitation.isExpired(~invitation=inv, ~now), false)
  })

  test("returns true for an expired pending invitation", () => {
    let inv = makePending(~expiresAt=pastExpiry, ())
    equal(Invitation.isExpired(~invitation=inv, ~now), true)
  })

  test("returns false for an accepted invitation even if past expiry", () => {
    let inv = {...makeAccepted(), expiresAt: pastExpiry}
    equal(Invitation.isExpired(~invitation=inv, ~now), false)
  })

  test("returns false for a revoked invitation even if past expiry", () => {
    let inv = {...makeRevoked(), expiresAt: pastExpiry}
    equal(Invitation.isExpired(~invitation=inv, ~now), false)
  })
})

// ─── accept ─────────────────────────────────────────────────────

describe("accept", () => {
  test("succeeds for a pending invitation with matching email", () => {
    let inv = makePending()
    let result = Invitation.accept(~invitation=inv, ~acceptedBy=accepterId, ~acceptedByEmail=email, ~now)
    switch result {
    | Ok(accepted) =>
      equal(accepted.status, Invitation.Accepted)
      equal(accepted.acceptedBy, Some(accepterId))
      equal(accepted.acceptedAt, Some(now))
    | Error(_) => ok(false)
    }
  })

  test("fails with EmailMismatch when email doesn't match", () => {
    let inv = makePending()
    let result = Invitation.accept(
      ~invitation=inv,
      ~acceptedBy=accepterId,
      ~acceptedByEmail=differentEmail,
      ~now,
    )
    equal(result, Error(#EmailMismatch))
  })

  test("fails with AlreadyAccepted for an accepted invitation", () => {
    let inv = makeAccepted()
    let result = Invitation.accept(~invitation=inv, ~acceptedBy=accepterId, ~acceptedByEmail=email, ~now)
    equal(result, Error(#AlreadyAccepted))
  })

  test("fails with AlreadyRevoked for a revoked invitation", () => {
    let inv = makeRevoked()
    let result = Invitation.accept(~invitation=inv, ~acceptedBy=accepterId, ~acceptedByEmail=email, ~now)
    equal(result, Error(#AlreadyRevoked))
  })

  test("fails with InvitationExpired for an expired pending invitation", () => {
    let inv = makePending(~expiresAt=pastExpiry, ())
    let result = Invitation.accept(~invitation=inv, ~acceptedBy=accepterId, ~acceptedByEmail=email, ~now)
    equal(result, Error(#InvitationExpired))
  })

  test("preserves all other fields on successful accept", () => {
    let inv = makePending()
    switch Invitation.accept(~invitation=inv, ~acceptedBy=accepterId, ~acceptedByEmail=email, ~now) {
    | Ok(accepted) =>
      equal(accepted.invitationId, inv.invitationId)
      equal(accepted.organizationId, inv.organizationId)
      equal(accepted.organizationName, inv.organizationName)
      equal(accepted.email, inv.email)
      equal(accepted.role, inv.role)
      equal(accepted.tokenHash, inv.tokenHash)
      equal(accepted.expiresAt, inv.expiresAt)
      equal(accepted.createdBy, inv.createdBy)
      equal(accepted.createdAt, inv.createdAt)
      equal(accepted.revokedBy, None)
      equal(accepted.revokedAt, None)
    | Error(_) => ok(false)
    }
  })
})

// ─── revoke ─────────────────────────────────────────────────────

describe("revoke", () => {
  test("succeeds for a pending invitation", () => {
    let inv = makePending()
    let result = Invitation.revoke(~invitation=inv, ~revokedBy=revokerId, ~now)
    switch result {
    | Ok(revoked) =>
      equal(revoked.status, Invitation.Revoked)
      equal(revoked.revokedBy, Some(revokerId))
      equal(revoked.revokedAt, Some(now))
    | Error(_) => ok(false)
    }
  })

  test("fails with AlreadyAccepted for an accepted invitation", () => {
    let inv = makeAccepted()
    let result = Invitation.revoke(~invitation=inv, ~revokedBy=revokerId, ~now)
    equal(result, Error(#AlreadyAccepted))
  })

  test("fails with AlreadyRevoked for a revoked invitation", () => {
    let inv = makeRevoked()
    let result = Invitation.revoke(~invitation=inv, ~revokedBy=revokerId, ~now)
    equal(result, Error(#AlreadyRevoked))
  })

  test("fails with InvitationExpired for an expired pending invitation", () => {
    let inv = makePending(~expiresAt=pastExpiry, ())
    let result = Invitation.revoke(~invitation=inv, ~revokedBy=revokerId, ~now)
    equal(result, Error(#InvitationExpired))
  })

  test("preserves all other fields on successful revoke", () => {
    let inv = makePending()
    switch Invitation.revoke(~invitation=inv, ~revokedBy=revokerId, ~now) {
    | Ok(revoked) =>
      equal(revoked.invitationId, inv.invitationId)
      equal(revoked.organizationId, inv.organizationId)
      equal(revoked.email, inv.email)
      equal(revoked.role, inv.role)
      equal(revoked.acceptedBy, None)
      equal(revoked.acceptedAt, None)
    | Error(_) => ok(false)
    }
  })
})

// ─── statusToString / statusOfString ────────────────────────────

describe("statusToString", () => {
  test("converts Pending", () => equal(Invitation.statusToString(Pending), "Pending"))
  test("converts Accepted", () => equal(Invitation.statusToString(Accepted), "Accepted"))
  test("converts Revoked", () => equal(Invitation.statusToString(Revoked), "Revoked"))
})

describe("statusOfString", () => {
  test("parses Pending", () => equal(Invitation.statusOfString("Pending"), Some(Invitation.Pending)))
  test("parses Accepted", () => equal(Invitation.statusOfString("Accepted"), Some(Invitation.Accepted)))
  test("parses Revoked", () => equal(Invitation.statusOfString("Revoked"), Some(Invitation.Revoked)))
  test("returns None for unknown", () => equal(Invitation.statusOfString("invalid"), None))
  test("returns None for empty string", () => equal(Invitation.statusOfString(""), None))
})

// ─── defaultExpirationMs ────────────────────────────────────────

describe("defaultExpirationMs", () => {
  test("equals 7 days in milliseconds", () => {
    equal(Invitation.defaultExpirationMs, 7.0 *. 24.0 *. 60.0 *. 60.0 *. 1000.0)
  })
})
