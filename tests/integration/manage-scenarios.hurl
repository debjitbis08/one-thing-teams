# ============================================================
# Manage Scenarios Integration Tests
# ============================================================

# ------------------------------------------------------------
# 1. Register, login, create product, initiative & user story
# ------------------------------------------------------------

POST {{base_url}}/api/register
Content-Type: application/json

{
  "email": "{{email}}",
  "username": "{{username}}",
  "displayName": "Scenario Test User {{unique}}",
  "password": "{{password}}",
  "confirmPassword": "{{password}}",
  "initialOrganizationName": "Scenario Org {{unique}}"
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
  "name": "Scenario Test Product {{unique}}"
}

HTTP/1.1 201
[Captures]
product_id: jsonpath "$.productId"

POST {{base_url}}/api/initiatives
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "productId": "{{product_id}}",
  "title": "Scenario Test Initiative {{unique}}"
}

HTTP/1.1 201
[Captures]
initiative_id: jsonpath "$.initiativeId"

POST {{base_url}}/api/tasks
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "title": "User can manage profile {{unique}}",
  "kind": "user_story",
  "initiativeId": "{{initiative_id}}"
}

HTTP/1.1 201
[Captures]
task_id: jsonpath "$.taskId"

# ------------------------------------------------------------
# 2. Add a scenario to the user story
# ------------------------------------------------------------

POST {{base_url}}/api/tasks/{{task_id}}/scenarios
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "title": "User updates display name"
}

HTTP/1.1 201
[Asserts]
jsonpath "$.scenarioId" exists
jsonpath "$.title" == "User updates display name"
[Captures]
scenario_id_1: jsonpath "$.scenarioId"

# ------------------------------------------------------------
# 3. Add a second scenario
# ------------------------------------------------------------

POST {{base_url}}/api/tasks/{{task_id}}/scenarios
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "title": "User uploads avatar"
}

HTTP/1.1 201
[Asserts]
jsonpath "$.scenarioId" exists
jsonpath "$.title" == "User uploads avatar"
[Captures]
scenario_id_2: jsonpath "$.scenarioId"

# ------------------------------------------------------------
# 4. Remove the first scenario
# ------------------------------------------------------------

DELETE {{base_url}}/api/tasks/{{task_id}}/scenarios/{{scenario_id_1}}
Cookie: sessionToken={{owner_session_token}}

HTTP/1.1 200
[Asserts]
jsonpath "$.success" == true

# ------------------------------------------------------------
# 5. Add scenario without title - should fail
# ------------------------------------------------------------

POST {{base_url}}/api/tasks/{{task_id}}/scenarios
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 6. Add scenario without auth - should fail
# ------------------------------------------------------------

POST {{base_url}}/api/tasks/{{task_id}}/scenarios
Content-Type: application/json

{
  "title": "Unauthorized scenario"
}

HTTP/1.1 401
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 7. Add scenario to non-existent task - should fail
# ------------------------------------------------------------

POST {{base_url}}/api/tasks/00000000-0000-0000-0000-000000000000/scenarios
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "title": "Ghost scenario"
}

HTTP/1.1 404
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 8. Add scenario to initiative task (not user story) - should fail
# ------------------------------------------------------------

POST {{base_url}}/api/tasks
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "title": "Regular initiative task {{unique}}",
  "kind": "initiative_task",
  "initiativeId": "{{initiative_id}}"
}

HTTP/1.1 201
[Captures]
initiative_task_id: jsonpath "$.taskId"

POST {{base_url}}/api/tasks/{{initiative_task_id}}/scenarios
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "title": "Should not be allowed"
}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 9. Remove scenario without auth - should fail
# ------------------------------------------------------------

DELETE {{base_url}}/api/tasks/{{task_id}}/scenarios/{{scenario_id_2}}

HTTP/1.1 401
[Asserts]
jsonpath "$.error" exists
