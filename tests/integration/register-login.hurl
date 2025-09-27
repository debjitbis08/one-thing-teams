# ------------------------------------------------------------
# Register a new user
# ------------------------------------------------------------

POST {{base_url}}/api/register
Content-Type: application/json

{
  "email": "{{email}}",
  "username": "{{username}}",
  "displayName": "Integration User {{unique}}",
  "password": "{{password}}",
  "confirmPassword": "{{password}}",
  "initialOrganizationName": "Integration Org {{unique}}"
}

HTTP/1.1 201
[Captures]
registered_user_id: jsonpath "$.userId"
registered_organization_id: jsonpath "$.organizationId"

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
login_user_id: jsonpath "$.user.userId"
session_token: jsonpath "$.tokens.sessionToken"
session_jwt: jsonpath "$.tokens.sessionJwt"

[Asserts]
jsonpath "$..sessionToken" exists
jsonpath "$..sessionJwt" exists
jsonpath "$.user.userId" == "{{registered_user_id}}"
jsonpath "$.user.organizationId" == "{{registered_organization_id}}"
