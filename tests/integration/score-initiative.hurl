# ============================================================
# Score Initiative Integration Tests
# ============================================================

# ------------------------------------------------------------
# 1. Register a user (OWNER), login, create product & initiative
# ------------------------------------------------------------

POST {{base_url}}/api/register
Content-Type: application/json

{
  "email": "{{email}}",
  "username": "{{username}}",
  "displayName": "Score Test User {{unique}}",
  "password": "{{password}}",
  "confirmPassword": "{{password}}",
  "initialOrganizationName": "Score Org {{unique}}"
}

HTTP/1.1 201
[Captures]
owner_user_id: jsonpath "$.userId"
organization_id: jsonpath "$.organizationId"

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
  "name": "Score Test Product {{unique}}"
}

HTTP/1.1 201
[Captures]
product_id: jsonpath "$.productId"

POST {{base_url}}/api/initiatives
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "productId": "{{product_id}}",
  "title": "Scoreable initiative {{unique}}"
}

HTTP/1.1 201
[Captures]
initiative_id: jsonpath "$.initiativeId"

# ------------------------------------------------------------
# 2. Score with proxy scoring
# ------------------------------------------------------------

PUT {{base_url}}/api/initiatives/{{initiative_id}}/score
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "scoreType": "proxy",
  "userValue": { "value": 8, "note": "High user demand" },
  "timeCriticality": { "value": 5 },
  "riskReduction": { "value": 3, "note": "Reduces churn risk" },
  "effort": { "value": 5 },
  "isCore": true
}

HTTP/1.1 200
[Asserts]
jsonpath "$.success" == true

# ------------------------------------------------------------
# 3. Re-score with break-even scoring (replaces previous)
# ------------------------------------------------------------

PUT {{base_url}}/api/initiatives/{{initiative_id}}/score
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "scoreType": "break_even",
  "contributionCount": 2.5,
  "effort": { "value": 3 },
  "isCore": false
}

HTTP/1.1 200
[Asserts]
jsonpath "$.success" == true

# ------------------------------------------------------------
# 4. Reject invalid scoreType
# ------------------------------------------------------------

PUT {{base_url}}/api/initiatives/{{initiative_id}}/score
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "scoreType": "unknown"
}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 5. Reject proxy scoring with missing fields
# ------------------------------------------------------------

PUT {{base_url}}/api/initiatives/{{initiative_id}}/score
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "scoreType": "proxy",
  "userValue": { "value": 8 }
}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 6. Reject break-even scoring with missing fields
# ------------------------------------------------------------

PUT {{base_url}}/api/initiatives/{{initiative_id}}/score
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "scoreType": "break_even",
  "contributionCount": 2.5
}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 7. Reject invalid Fibonacci value
# ------------------------------------------------------------

PUT {{base_url}}/api/initiatives/{{initiative_id}}/score
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "scoreType": "proxy",
  "userValue": { "value": 7 },
  "timeCriticality": { "value": 5 },
  "riskReduction": { "value": 3 },
  "effort": { "value": 5 },
  "isCore": false
}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 8. Reject scoring non-existent initiative
# ------------------------------------------------------------

PUT {{base_url}}/api/initiatives/019cc000-0000-7000-8000-000000000000/score
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "scoreType": "proxy",
  "userValue": { "value": 8 },
  "timeCriticality": { "value": 5 },
  "riskReduction": { "value": 3 },
  "effort": { "value": 5 },
  "isCore": false
}

HTTP/1.1 404
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 9. Reject unauthenticated request
# ------------------------------------------------------------

PUT {{base_url}}/api/initiatives/{{initiative_id}}/score
Content-Type: application/json

{
  "scoreType": "proxy",
  "userValue": { "value": 8 },
  "timeCriticality": { "value": 5 },
  "riskReduction": { "value": 3 },
  "effort": { "value": 5 },
  "isCore": false
}

HTTP/1.1 401
