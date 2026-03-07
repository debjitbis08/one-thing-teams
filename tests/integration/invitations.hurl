# ============================================================
# Invitation Flow Integration Tests
# ============================================================

# ------------------------------------------------------------
# 1. Register the inviter (OWNER) and login
# ------------------------------------------------------------

POST {{base_url}}/api/register
Content-Type: application/json

{
  "email": "{{email}}",
  "username": "{{username}}",
  "displayName": "Inviter {{unique}}",
  "password": "{{password}}",
  "confirmPassword": "{{password}}",
  "initialOrganizationName": "Invite Test Org {{unique}}"
}

HTTP/1.1 201
[Captures]
inviter_user_id: jsonpath "$.userId"
organization_id: jsonpath "$.organizationId"

POST {{base_url}}/api/login
Content-Type: application/json

{
  "usernameOrEmail": "{{email}}",
  "password": "{{password}}"
}

HTTP/1.1 200
[Captures]
inviter_session_token: jsonpath "$.tokens.sessionToken"

# ------------------------------------------------------------
# 2. Create an invitation
# ------------------------------------------------------------

POST {{base_url}}/api/invitations
Content-Type: application/json
Cookie: sessionToken={{inviter_session_token}}

{
  "email": "invitee_{{unique}}@example.com",
  "role": "EDITOR"
}

HTTP/1.1 201
[Captures]
invitation_id: jsonpath "$.invitationId"
invitation_token: jsonpath "$.token"

[Asserts]
jsonpath "$.invitationId" exists
jsonpath "$.token" exists
jsonpath "$.expiresAt" exists

# ------------------------------------------------------------
# 3. List pending invitations - should see the one we created
# ------------------------------------------------------------

GET {{base_url}}/api/invitations
Cookie: sessionToken={{inviter_session_token}}

HTTP/1.1 200
[Asserts]
jsonpath "$.invitations" count == 1
jsonpath "$.invitations[0].invitationId" == "{{invitation_id}}"
jsonpath "$.invitations[0].email" == "invitee_{{unique}}@example.com"
jsonpath "$.invitations[0].role" == "EDITOR"

# ------------------------------------------------------------
# 4. Create a second invitation (to be revoked)
# ------------------------------------------------------------

POST {{base_url}}/api/invitations
Content-Type: application/json
Cookie: sessionToken={{inviter_session_token}}

{
  "email": "revokee_{{unique}}@example.com",
  "role": "VIEWER"
}

HTTP/1.1 201
[Captures]
revoke_invitation_id: jsonpath "$.invitationId"

# Verify we now have 2 pending invitations
GET {{base_url}}/api/invitations
Cookie: sessionToken={{inviter_session_token}}

HTTP/1.1 200
[Asserts]
jsonpath "$.invitations" count == 2

# ------------------------------------------------------------
# 5. Revoke the second invitation
# ------------------------------------------------------------

DELETE {{base_url}}/api/invitations/{{revoke_invitation_id}}
Cookie: sessionToken={{inviter_session_token}}

HTTP/1.1 200
[Asserts]
jsonpath "$.success" == true

# Verify only 1 pending invitation remains
GET {{base_url}}/api/invitations
Cookie: sessionToken={{inviter_session_token}}

HTTP/1.1 200
[Asserts]
jsonpath "$.invitations" count == 1
jsonpath "$.invitations[0].invitationId" == "{{invitation_id}}"

# ------------------------------------------------------------
# 6. Revoking an already-revoked invitation fails
# ------------------------------------------------------------

DELETE {{base_url}}/api/invitations/{{revoke_invitation_id}}
Cookie: sessionToken={{inviter_session_token}}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 7. Register the invitee and login
# ------------------------------------------------------------

POST {{base_url}}/api/register
Content-Type: application/json

{
  "email": "invitee_{{unique}}@example.com",
  "username": "invitee_{{unique}}",
  "displayName": "Invitee {{unique}}",
  "password": "{{password}}",
  "confirmPassword": "{{password}}",
  "initialOrganizationName": "Invitee Own Org {{unique}}"
}

HTTP/1.1 201

POST {{base_url}}/api/login
Content-Type: application/json

{
  "usernameOrEmail": "invitee_{{unique}}@example.com",
  "password": "{{password}}"
}

HTTP/1.1 200
[Captures]
invitee_session_token: jsonpath "$.tokens.sessionToken"

# ------------------------------------------------------------
# 8. Accept the invitation
# ------------------------------------------------------------

POST {{base_url}}/api/invitations/accept
Content-Type: application/json
Cookie: sessionToken={{invitee_session_token}}

{
  "token": "{{invitation_token}}"
}

HTTP/1.1 200
[Asserts]
jsonpath "$.organizationId" == "{{organization_id}}"
jsonpath "$.role" == "EDITOR"

# ------------------------------------------------------------
# 9. Accepting the same invitation again fails
# ------------------------------------------------------------

POST {{base_url}}/api/invitations/accept
Content-Type: application/json
Cookie: sessionToken={{invitee_session_token}}

{
  "token": "{{invitation_token}}"
}

HTTP/1.1 409
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 10. Inviter sees no more pending invitations
# ------------------------------------------------------------

GET {{base_url}}/api/invitations
Cookie: sessionToken={{inviter_session_token}}

HTTP/1.1 200
[Asserts]
jsonpath "$.invitations" count == 0

# ------------------------------------------------------------
# 11. Validation: invalid role is rejected
# ------------------------------------------------------------

POST {{base_url}}/api/invitations
Content-Type: application/json
Cookie: sessionToken={{inviter_session_token}}

{
  "email": "someone@example.com",
  "role": "OWNER"
}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 12. Validation: invalid email is rejected
# ------------------------------------------------------------

POST {{base_url}}/api/invitations
Content-Type: application/json
Cookie: sessionToken={{inviter_session_token}}

{
  "email": "not-an-email",
  "role": "VIEWER"
}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 13. Unauthenticated requests are rejected
# ------------------------------------------------------------

POST {{base_url}}/api/invitations
Content-Type: application/json

{
  "email": "someone@example.com",
  "role": "EDITOR"
}

HTTP/1.1 401

GET {{base_url}}/api/invitations

HTTP/1.1 401

# ------------------------------------------------------------
# 14. Email mismatch: wrong user cannot accept
# ------------------------------------------------------------

POST {{base_url}}/api/invitations
Content-Type: application/json
Cookie: sessionToken={{inviter_session_token}}

{
  "email": "wrongperson_{{unique}}@example.com",
  "role": "VIEWER"
}

HTTP/1.1 201
[Captures]
mismatch_token: jsonpath "$.token"

# The invitee (different email) tries to accept
POST {{base_url}}/api/invitations/accept
Content-Type: application/json
Cookie: sessionToken={{invitee_session_token}}

{
  "token": "{{mismatch_token}}"
}

HTTP/1.1 403
[Asserts]
jsonpath "$.error" exists
