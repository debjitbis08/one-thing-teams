# ============================================================
# Create Initiative Integration Tests
# ============================================================

# ------------------------------------------------------------
# 1. Register a user (OWNER), login, and create a product
# ------------------------------------------------------------

POST {{base_url}}/api/register
Content-Type: application/json

{
  "email": "{{email}}",
  "username": "{{username}}",
  "displayName": "Initiative Test User {{unique}}",
  "password": "{{password}}",
  "confirmPassword": "{{password}}",
  "initialOrganizationName": "Init Org {{unique}}"
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
  "name": "Initiative Test Product {{unique}}"
}

HTTP/1.1 201
[Captures]
product_id: jsonpath "$.productId"

# ------------------------------------------------------------
# 2. Create an initiative with all fields
# ------------------------------------------------------------

POST {{base_url}}/api/initiatives
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "productId": "{{product_id}}",
  "title": "Build onboarding flow {{unique}}",
  "description": "Improve the first-time user experience",
  "timeBudget": 40.0,
  "chatRoomLink": "https://chat.example.com/onboarding"
}

HTTP/1.1 201
[Captures]
initiative_id: jsonpath "$.initiativeId"

[Asserts]
jsonpath "$.initiativeId" exists
jsonpath "$.productId" == "{{product_id}}"
jsonpath "$.title" == "Build onboarding flow {{unique}}"

# ------------------------------------------------------------
# 3. Create an initiative with minimal fields
# ------------------------------------------------------------

POST {{base_url}}/api/initiatives
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "productId": "{{product_id}}",
  "title": "Quick fix {{unique}}"
}

HTTP/1.1 201
[Asserts]
jsonpath "$.initiativeId" exists
jsonpath "$.productId" == "{{product_id}}"
jsonpath "$.title" == "Quick fix {{unique}}"

# ------------------------------------------------------------
# 4. Reject empty title
# ------------------------------------------------------------

POST {{base_url}}/api/initiatives
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "productId": "{{product_id}}",
  "title": ""
}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 5. Reject missing productId
# ------------------------------------------------------------

POST {{base_url}}/api/initiatives
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "title": "No product"
}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 6. Reject non-existent product
# ------------------------------------------------------------

POST {{base_url}}/api/initiatives
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "productId": "019cc000-0000-7000-8000-000000000000",
  "title": "Orphan initiative {{unique}}"
}

HTTP/1.1 404
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 7. Reject negative time budget
# ------------------------------------------------------------

POST {{base_url}}/api/initiatives
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "productId": "{{product_id}}",
  "title": "Bad budget {{unique}}",
  "timeBudget": -10
}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 8. Reject unauthenticated request
# ------------------------------------------------------------

POST {{base_url}}/api/initiatives
Content-Type: application/json

{
  "productId": "{{product_id}}",
  "title": "Should fail {{unique}}"
}

HTTP/1.1 401
