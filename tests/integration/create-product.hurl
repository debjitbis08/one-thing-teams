# ============================================================
# Create Product Integration Tests
# ============================================================

# ------------------------------------------------------------
# 1. Register a user (OWNER) and login
# ------------------------------------------------------------

POST {{base_url}}/api/register
Content-Type: application/json

{
  "email": "{{email}}",
  "username": "{{username}}",
  "displayName": "Product Test User {{unique}}",
  "password": "{{password}}",
  "confirmPassword": "{{password}}",
  "initialOrganizationName": "Product Test Org {{unique}}"
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

# ------------------------------------------------------------
# 2. Create a product
# ------------------------------------------------------------

POST {{base_url}}/api/products
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "name": "My Product {{unique}}",
  "description": "A test product"
}

HTTP/1.1 201
[Captures]
product_id: jsonpath "$.productId"
product_short_code: jsonpath "$.shortCode"

[Asserts]
jsonpath "$.productId" exists
jsonpath "$.name" == "My Product {{unique}}"
jsonpath "$.shortCode" exists

# ------------------------------------------------------------
# 3. Create a product without description
# ------------------------------------------------------------

POST {{base_url}}/api/products
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "name": "Bare Product {{unique}}"
}

HTTP/1.1 201
[Asserts]
jsonpath "$.productId" exists
jsonpath "$.name" == "Bare Product {{unique}}"
jsonpath "$.shortCode" exists

# ------------------------------------------------------------
# 4. Reject empty product name
# ------------------------------------------------------------

POST {{base_url}}/api/products
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "name": ""
}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 5. Reject missing name field
# ------------------------------------------------------------

POST {{base_url}}/api/products
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "description": "No name provided"
}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 6. Reject unauthenticated request
# ------------------------------------------------------------

POST {{base_url}}/api/products
Content-Type: application/json

{
  "name": "Should Fail {{unique}}"
}

HTTP/1.1 401
