# ============================================================
# Initiative Status Integration Tests
# (progress status & lifecycle status)
# ============================================================

# ------------------------------------------------------------
# 1. Setup: Register, login, create product & initiative
# ------------------------------------------------------------

POST {{base_url}}/api/register
Content-Type: application/json

{
  "email": "{{email}}",
  "username": "{{username}}",
  "displayName": "Init Status User {{unique}}",
  "password": "{{password}}",
  "confirmPassword": "{{password}}",
  "initialOrganizationName": "Init Status Org {{unique}}"
}

HTTP/1.1 201
[Captures]
owner_user_id: jsonpath "$.userId"

POST {{base_url}}/api/login
Content-Type: application/json

{
  "usernameOrEmail": "{{email}}",
  "password": "{{password}}"
}

HTTP/1.1 200
[Captures]
owner_session_token: jsonpath "$.tokens.sessionToken"

POST {{base_url}}/api/products
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "name": "Init Status Product {{unique}}"
}

HTTP/1.1 201
[Captures]
product_id: jsonpath "$.productId"

POST {{base_url}}/api/initiatives
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "productId": "{{product_id}}",
  "title": "Init Status Initiative {{unique}}"
}

HTTP/1.1 201
[Captures]
initiative_id: jsonpath "$.initiativeId"

# ------------------------------------------------------------
# 2. Update progress status: thinking
# ------------------------------------------------------------

PATCH {{base_url}}/api/initiatives/{{initiative_id}}/progress-status
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "progressStatus": "thinking"
}

HTTP/1.1 200
[Asserts]
jsonpath "$.success" == true

# ------------------------------------------------------------
# 3. Update progress status: building
# ------------------------------------------------------------

PATCH {{base_url}}/api/initiatives/{{initiative_id}}/progress-status
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "progressStatus": "building"
}

HTTP/1.1 200
[Asserts]
jsonpath "$.success" == true

# ------------------------------------------------------------
# 4. Update progress status: deploying
# ------------------------------------------------------------

PATCH {{base_url}}/api/initiatives/{{initiative_id}}/progress-status
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "progressStatus": "deploying"
}

HTTP/1.1 200
[Asserts]
jsonpath "$.success" == true

# ------------------------------------------------------------
# 5. Invalid progress status
# ------------------------------------------------------------

PATCH {{base_url}}/api/initiatives/{{initiative_id}}/progress-status
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "progressStatus": "invalid_status"
}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 6. Progress status without auth
# ------------------------------------------------------------

PATCH {{base_url}}/api/initiatives/{{initiative_id}}/progress-status
Content-Type: application/json

{
  "progressStatus": "building"
}

HTTP/1.1 401
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 7. Progress status on non-existent initiative
# ------------------------------------------------------------

PATCH {{base_url}}/api/initiatives/00000000-0000-0000-0000-000000000000/progress-status
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "progressStatus": "building"
}

HTTP/1.1 404
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 8. Update lifecycle status: active
# ------------------------------------------------------------

PATCH {{base_url}}/api/initiatives/{{initiative_id}}/lifecycle-status
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "lifecycleStatus": "active"
}

HTTP/1.1 200
[Asserts]
jsonpath "$.success" == true

# ------------------------------------------------------------
# 9. Update lifecycle status: done with evidence
# ------------------------------------------------------------

PATCH {{base_url}}/api/initiatives/{{initiative_id}}/lifecycle-status
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "lifecycleStatus": "done",
  "doneEvidence": "All tasks completed and deployed",
  "outcomeNotes": "Delivered on time with positive user feedback"
}

HTTP/1.1 200
[Asserts]
jsonpath "$.success" == true

# ------------------------------------------------------------
# 10. Invalid lifecycle status
# ------------------------------------------------------------

PATCH {{base_url}}/api/initiatives/{{initiative_id}}/lifecycle-status
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "lifecycleStatus": "invalid_status"
}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 11. Lifecycle status without auth
# ------------------------------------------------------------

PATCH {{base_url}}/api/initiatives/{{initiative_id}}/lifecycle-status
Content-Type: application/json

{
  "lifecycleStatus": "active"
}

HTTP/1.1 401
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 12. Lifecycle status on non-existent initiative
# ------------------------------------------------------------

PATCH {{base_url}}/api/initiatives/00000000-0000-0000-0000-000000000000/lifecycle-status
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "lifecycleStatus": "active"
}

HTTP/1.1 404
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 13. Update lifecycle to abandoned with outcome notes
# ------------------------------------------------------------

POST {{base_url}}/api/initiatives
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "productId": "{{product_id}}",
  "title": "Abandoned Initiative {{unique}}"
}

HTTP/1.1 201
[Captures]
abandoned_initiative_id: jsonpath "$.initiativeId"

PATCH {{base_url}}/api/initiatives/{{abandoned_initiative_id}}/lifecycle-status
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "lifecycleStatus": "abandoned",
  "outcomeNotes": "Market conditions changed, no longer viable"
}

HTTP/1.1 200
[Asserts]
jsonpath "$.success" == true

# ------------------------------------------------------------
# 14. Missing progressStatus field
# ------------------------------------------------------------

PATCH {{base_url}}/api/initiatives/{{initiative_id}}/progress-status
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 15. Missing lifecycleStatus field
# ------------------------------------------------------------

PATCH {{base_url}}/api/initiatives/{{initiative_id}}/lifecycle-status
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" exists
