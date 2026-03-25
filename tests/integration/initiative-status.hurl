# ============================================================
# Initiative Status Integration Tests
# (progress status & lifecycle status with structured evidence)
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
# 9. Done WITHOUT evidence → blocked (400)
# ------------------------------------------------------------

PATCH {{base_url}}/api/initiatives/{{initiative_id}}/lifecycle-status
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "lifecycleStatus": "done"
}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 10. Done with empty evidence array → blocked (400)
# ------------------------------------------------------------

PATCH {{base_url}}/api/initiatives/{{initiative_id}}/lifecycle-status
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "lifecycleStatus": "done",
  "evidence": []
}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 11. Done with live_url evidence → success
# ------------------------------------------------------------

PATCH {{base_url}}/api/initiatives/{{initiative_id}}/lifecycle-status
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "lifecycleStatus": "done",
  "evidence": [
    { "kind": "live_url", "url": "https://app.example.com/feature" }
  ],
  "outcomeNotes": "Delivered on time with positive user feedback"
}

HTTP/1.1 200
[Asserts]
jsonpath "$.success" == true

# ------------------------------------------------------------
# 12. New initiative: done with tracking_event evidence
# ------------------------------------------------------------

POST {{base_url}}/api/initiatives
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "productId": "{{product_id}}",
  "title": "Tracking Evidence Initiative {{unique}}"
}

HTTP/1.1 201
[Captures]
tracking_initiative_id: jsonpath "$.initiativeId"

PATCH {{base_url}}/api/initiatives/{{tracking_initiative_id}}/lifecycle-status
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "lifecycleStatus": "done",
  "evidence": [
    { "kind": "tracking_event", "description": "user_signup event confirmed in analytics" }
  ]
}

HTTP/1.1 200
[Asserts]
jsonpath "$.success" == true

# ------------------------------------------------------------
# 13. New initiative: done with screenshot evidence
# ------------------------------------------------------------

POST {{base_url}}/api/initiatives
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "productId": "{{product_id}}",
  "title": "Screenshot Evidence Initiative {{unique}}"
}

HTTP/1.1 201
[Captures]
screenshot_initiative_id: jsonpath "$.initiativeId"

PATCH {{base_url}}/api/initiatives/{{screenshot_initiative_id}}/lifecycle-status
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "lifecycleStatus": "done",
  "evidence": [
    { "kind": "screenshot", "url": "https://storage.example.com/screenshots/deploy-evidence.png" }
  ]
}

HTTP/1.1 200
[Asserts]
jsonpath "$.success" == true

# ------------------------------------------------------------
# 14. New initiative: done with manual_sign_off (override)
# ------------------------------------------------------------

POST {{base_url}}/api/initiatives
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "productId": "{{product_id}}",
  "title": "Manual SignOff Initiative {{unique}}"
}

HTTP/1.1 201
[Captures]
signoff_initiative_id: jsonpath "$.initiativeId"

PATCH {{base_url}}/api/initiatives/{{signoff_initiative_id}}/lifecycle-status
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "lifecycleStatus": "done",
  "evidence": [
    { "kind": "manual_sign_off", "signedOffBy": "product-lead@example.com", "reason": "Validated deployment in staging with UX team" }
  ]
}

HTTP/1.1 200
[Asserts]
jsonpath "$.success" == true

# ------------------------------------------------------------
# 15. Done with multiple evidence items
# ------------------------------------------------------------

POST {{base_url}}/api/initiatives
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "productId": "{{product_id}}",
  "title": "Multi Evidence Initiative {{unique}}"
}

HTTP/1.1 201
[Captures]
multi_initiative_id: jsonpath "$.initiativeId"

PATCH {{base_url}}/api/initiatives/{{multi_initiative_id}}/lifecycle-status
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "lifecycleStatus": "done",
  "evidence": [
    { "kind": "live_url", "url": "https://app.example.com/new-feature" },
    { "kind": "tracking_event", "description": "feature_used event firing in production" },
    { "kind": "screenshot", "url": "https://storage.example.com/screenshots/prod.png" }
  ],
  "outcomeNotes": "Feature launched with 3 types of validation"
}

HTTP/1.1 200
[Asserts]
jsonpath "$.success" == true

# ------------------------------------------------------------
# 16. Invalid evidence: live_url missing url field
# ------------------------------------------------------------

POST {{base_url}}/api/initiatives
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "productId": "{{product_id}}",
  "title": "Bad Evidence Initiative {{unique}}"
}

HTTP/1.1 201
[Captures]
bad_evidence_initiative_id: jsonpath "$.initiativeId"

PATCH {{base_url}}/api/initiatives/{{bad_evidence_initiative_id}}/lifecycle-status
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "lifecycleStatus": "done",
  "evidence": [
    { "kind": "live_url" }
  ]
}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 17. Invalid evidence: manual_sign_off missing reason
# ------------------------------------------------------------

PATCH {{base_url}}/api/initiatives/{{bad_evidence_initiative_id}}/lifecycle-status
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "lifecycleStatus": "done",
  "evidence": [
    { "kind": "manual_sign_off", "signedOffBy": "someone@example.com" }
  ]
}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 18. Invalid evidence: unknown kind
# ------------------------------------------------------------

PATCH {{base_url}}/api/initiatives/{{bad_evidence_initiative_id}}/lifecycle-status
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "lifecycleStatus": "done",
  "evidence": [
    { "kind": "email_confirmation", "description": "got an email" }
  ]
}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 19. Invalid lifecycle status
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
# 20. Lifecycle status without auth
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
# 21. Lifecycle status on non-existent initiative
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
# 22. Abandoned with outcome notes (no evidence needed)
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
# 23. Missing lifecycleStatus field
# ------------------------------------------------------------

PATCH {{base_url}}/api/initiatives/{{initiative_id}}/lifecycle-status
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 24. Missing progressStatus field
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
# 25. Invalid evidence: tracking_event missing description
# ------------------------------------------------------------

PATCH {{base_url}}/api/initiatives/{{bad_evidence_initiative_id}}/lifecycle-status
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "lifecycleStatus": "done",
  "evidence": [
    { "kind": "tracking_event" }
  ]
}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 26. Invalid evidence: screenshot missing url
# ------------------------------------------------------------

PATCH {{base_url}}/api/initiatives/{{bad_evidence_initiative_id}}/lifecycle-status
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "lifecycleStatus": "done",
  "evidence": [
    { "kind": "screenshot" }
  ]
}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" exists
