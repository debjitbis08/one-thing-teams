type invitationStatus =
  | Pending
  | Accepted
  | Revoked

type t = {
  invitationId: InvitationId.invitationId,
  organizationId: OrganizationId.organizationId,
  organizationName: string,
  email: Email.t,
  role: IdDomain.memberRole,
  tokenHash: string,
  status: invitationStatus,
  expiresAt: float,
  createdBy: UserId.userId,
  createdAt: float,
  acceptedBy: option<UserId.userId>,
  acceptedAt: option<float>,
  revokedBy: option<UserId.userId>,
  revokedAt: option<float>,
}

type createError = [
  | #InvalidEmail(string)
  | #InvalidRole
]

type acceptError = [
  | #AlreadyAccepted
  | #AlreadyRevoked
  | #InvitationExpired
  | #EmailMismatch
]

type revokeError = [
  | #AlreadyAccepted
  | #AlreadyRevoked
  | #InvitationExpired
]

let defaultExpirationMs = 7.0 *. 24.0 *. 60.0 *. 60.0 *. 1000.0

let isExpired = (~invitation: t, ~now: float) =>
  invitation.status == Pending && invitation.expiresAt < now

let effectiveStatus = (~invitation: t, ~now: float) =>
  switch invitation.status {
  | Pending if invitation.expiresAt < now => Revoked
  | other => other
  }

let accept = (~invitation: t, ~acceptedBy: UserId.userId, ~acceptedByEmail: Email.t, ~now: float): result<
  t,
  acceptError,
> =>
  switch effectiveStatus(~invitation, ~now) {
  | Accepted => Error(#AlreadyAccepted)
  | Revoked => Error(if isExpired(~invitation, ~now) {
      #InvitationExpired
    } else {
      #AlreadyRevoked
    })
  | Pending =>
    if !Email.equal(invitation.email, acceptedByEmail) {
      Error(#EmailMismatch)
    } else {
      Ok({
        ...invitation,
        status: Accepted,
        acceptedBy: Some(acceptedBy),
        acceptedAt: Some(now),
      })
    }
  }

let revoke = (~invitation: t, ~revokedBy: UserId.userId, ~now: float): result<t, revokeError> =>
  switch effectiveStatus(~invitation, ~now) {
  | Accepted => Error(#AlreadyAccepted)
  | Revoked => Error(if isExpired(~invitation, ~now) {
      #InvitationExpired
    } else {
      #AlreadyRevoked
    })
  | Pending =>
    Ok({
      ...invitation,
      status: Revoked,
      revokedBy: Some(revokedBy),
      revokedAt: Some(now),
    })
  }

let statusToString = status =>
  switch status {
  | Pending => "Pending"
  | Accepted => "Accepted"
  | Revoked => "Revoked"
  }

let statusOfString = status =>
  switch status {
  | "Pending" => Some(Pending)
  | "Accepted" => Some(Accepted)
  | "Revoked" => Some(Revoked)
  | _ => None
  }
