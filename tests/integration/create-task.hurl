# ============================================================
# Create Task Integration Tests
# ============================================================

# ------------------------------------------------------------
# 1. Register, login, create product & initiative
# ------------------------------------------------------------

POST {{base_url}}/api/register
Content-Type: application/json

{
  "email": "{{email}}",
  "username": "{{username}}",
  "displayName": "Task Test User {{unique}}",
  "password": "{{password}}",
  "confirmPassword": "{{password}}",
  "initialOrganizationName": "Task Org {{unique}}"
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
  "name": "Task Test Product {{unique}}"
}

HTTP/1.1 201
[Captures]
product_id: jsonpath "$.productId"

POST {{base_url}}/api/initiatives
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "productId": "{{product_id}}",
  "title": "Task Test Initiative {{unique}}"
}

HTTP/1.1 201
[Captures]
initiative_id: jsonpath "$.initiativeId"

# ------------------------------------------------------------
# 2. Create an initiative task
# ------------------------------------------------------------

POST {{base_url}}/api/tasks
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "title": "Implement login page {{unique}}",
  "kind": "initiative_task",
  "initiativeId": "{{initiative_id}}"
}

HTTP/1.1 201
[Asserts]
jsonpath "$.taskId" exists
jsonpath "$.title" == "Implement login page {{unique}}"
jsonpath "$.kind" == "initiative_task"

# ------------------------------------------------------------
# 3. Create an initiative task with description
# ------------------------------------------------------------

POST {{base_url}}/api/tasks
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "title": "Design database schema {{unique}}",
  "description": "Create the initial schema for user management",
  "kind": "initiative_task",
  "initiativeId": "{{initiative_id}}"
}

HTTP/1.1 201
[Asserts]
jsonpath "$.taskId" exists
jsonpath "$.title" == "Design database schema {{unique}}"

# ------------------------------------------------------------
# 4. Create a user story with scenarios
# ------------------------------------------------------------

POST {{base_url}}/api/tasks
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "title": "User can reset password {{unique}}",
  "kind": "user_story",
  "initiativeId": "{{initiative_id}}",
  "scenarios": [
    {
      "title": "Reset via email link",
      "acceptanceCriteria": ["User receives email within 1 minute", "Link expires after 24 hours"]
    }
  ]
}

HTTP/1.1 201
[Asserts]
jsonpath "$.taskId" exists
jsonpath "$.kind" == "user_story"

# ------------------------------------------------------------
# 5. Create a support task
# ------------------------------------------------------------

POST {{base_url}}/api/tasks
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "title": "Fix CSS rendering on Safari {{unique}}",
  "kind": "support",
  "productId": "{{product_id}}"
}

HTTP/1.1 201
[Asserts]
jsonpath "$.taskId" exists
jsonpath "$.kind" == "support"

# ------------------------------------------------------------
# 6. Reject missing title
# ------------------------------------------------------------

POST {{base_url}}/api/tasks
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "kind": "initiative_task",
  "initiativeId": "{{initiative_id}}"
}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 7. Reject missing kind
# ------------------------------------------------------------

POST {{base_url}}/api/tasks
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "title": "Some task {{unique}}"
}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 8. Reject invalid kind
# ------------------------------------------------------------

POST {{base_url}}/api/tasks
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "title": "Some task {{unique}}",
  "kind": "invalid_kind"
}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 9. Reject initiative_task without initiativeId
# ------------------------------------------------------------

POST {{base_url}}/api/tasks
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "title": "No initiative {{unique}}",
  "kind": "initiative_task"
}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 10. User story without scenarios succeeds
# ------------------------------------------------------------

POST {{base_url}}/api/tasks
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "title": "Story without scenarios {{unique}}",
  "kind": "user_story",
  "initiativeId": "{{initiative_id}}"
}

HTTP/1.1 201
[Asserts]
jsonpath "$.taskId" exists
jsonpath "$.kind" == "user_story"

# ------------------------------------------------------------
# 11. Reject support task without productId
# ------------------------------------------------------------

POST {{base_url}}/api/tasks
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "title": "Support without product {{unique}}",
  "kind": "support"
}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 12. Reject non-existent initiative
# ------------------------------------------------------------

POST {{base_url}}/api/tasks
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "title": "Orphan task {{unique}}",
  "kind": "initiative_task",
  "initiativeId": "019cc000-0000-7000-8000-000000000000"
}

HTTP/1.1 404
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 13. Reject non-existent product for support
# ------------------------------------------------------------

POST {{base_url}}/api/tasks
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "title": "Support orphan {{unique}}",
  "kind": "support",
  "productId": "019cc000-0000-7000-8000-000000000000"
}

HTTP/1.1 404
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 14. Reject unauthenticated request
# ------------------------------------------------------------

POST {{base_url}}/api/tasks
Content-Type: application/json

{
  "title": "Should fail {{unique}}",
  "kind": "initiative_task",
  "initiativeId": "{{initiative_id}}"
}

HTTP/1.1 401
