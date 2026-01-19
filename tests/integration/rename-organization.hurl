# ------------------------------------------------------------
# Register a new user with an initial organization
# ------------------------------------------------------------

POST {{base_url}}/api/register
Content-Type: application/json

{
  "email": "{{email}}",
  "username": "{{username}}",
  "displayName": "Rename Test User {{unique}}",
  "password": "{{password}}",
  "confirmPassword": "{{password}}",
  "initialOrganizationName": "Original Org Name {{unique}}"
}

HTTP/1.1 201
[Captures]
registered_user_id: jsonpath "$.userId"
registered_organization_id: jsonpath "$.organizationId"
original_org_name: jsonpath "$.organizationName"

# ------------------------------------------------------------
# Login with the registered credentials
# ------------------------------------------------------------

POST {{base_url}}/api/login
Content-Type: application/json

{
  "usernameOrEmail": "{{email}}",
  "password": "{{password}}"
}

HTTP/1.1 200
[Captures]
session_token: jsonpath "$.tokens.sessionToken"
session_jwt: jsonpath "$.tokens.sessionJwt"

[Asserts]
jsonpath "$.user.userId" == "{{registered_user_id}}"
jsonpath "$.user.organizationId" == "{{registered_organization_id}}"

# ------------------------------------------------------------
# Rename the organization
# ------------------------------------------------------------

PATCH {{base_url}}/api/organization
Content-Type: application/json
Cookie: sessionToken={{session_token}}

{
  "organizationId": "{{registered_organization_id}}",
  "name": "Renamed Org {{unique}}"
}

HTTP/1.1 202
[Asserts]
jsonpath "$.success" == true

# ------------------------------------------------------------
# Verify the rename by logging in again
# The organization name should be updated in the user snapshot
# ------------------------------------------------------------

POST {{base_url}}/api/login
Content-Type: application/json

{
  "usernameOrEmail": "{{email}}",
  "password": "{{password}}"
}

HTTP/1.1 200
[Asserts]
jsonpath "$.user.organizationName" == "Renamed Org {{unique}}"
jsonpath "$.user.organizationId" == "{{registered_organization_id}}"
