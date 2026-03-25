# ============================================================
# Read API Integration Tests
# (GET products, initiatives, initiative detail, tasks)
# ============================================================

# ------------------------------------------------------------
# 1. Setup: Register, login
# ------------------------------------------------------------

POST {{base_url}}/api/register
Content-Type: application/json

{
  "email": "{{email}}",
  "username": "{{username}}",
  "displayName": "Read API User {{unique}}",
  "password": "{{password}}",
  "confirmPassword": "{{password}}",
  "initialOrganizationName": "Read API Org {{unique}}"
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
session_token: jsonpath "$.tokens.sessionToken"

# ------------------------------------------------------------
# 2. List products — empty initially
# ------------------------------------------------------------

GET {{base_url}}/api/products
Cookie: sessionToken={{session_token}}

HTTP/1.1 200
[Asserts]
jsonpath "$.products" count == 0

# ------------------------------------------------------------
# 3. Create two products
# ------------------------------------------------------------

POST {{base_url}}/api/products
Content-Type: application/json
Cookie: sessionToken={{session_token}}

{
  "name": "Read API Product A {{unique}}"
}

HTTP/1.1 201
[Captures]
product_a_id: jsonpath "$.productId"

POST {{base_url}}/api/products
Content-Type: application/json
Cookie: sessionToken={{session_token}}

{
  "name": "Read API Product B {{unique}}"
}

HTTP/1.1 201
[Captures]
product_b_id: jsonpath "$.productId"

# ------------------------------------------------------------
# 4. List products — should see both
# ------------------------------------------------------------

GET {{base_url}}/api/products
Cookie: sessionToken={{session_token}}

HTTP/1.1 200
[Asserts]
jsonpath "$.products" count == 2
jsonpath "$.products[0].productId" == {{product_a_id}}
jsonpath "$.products[1].productId" == {{product_b_id}}
jsonpath "$.products[0].name" contains "Product A"
jsonpath "$.products[0].shortCode" exists

# ------------------------------------------------------------
# 5. List products — unauthorized
# ------------------------------------------------------------

GET {{base_url}}/api/products

HTTP/1.1 401

# ------------------------------------------------------------
# 6. List initiatives — empty for product A
# ------------------------------------------------------------

GET {{base_url}}/api/initiatives?productId={{product_a_id}}
Cookie: sessionToken={{session_token}}

HTTP/1.1 200
[Asserts]
jsonpath "$.initiatives" count == 0

# ------------------------------------------------------------
# 7. Create initiatives under product A
# ------------------------------------------------------------

POST {{base_url}}/api/initiatives
Content-Type: application/json
Cookie: sessionToken={{session_token}}

{
  "productId": "{{product_a_id}}",
  "title": "Initiative Alpha {{unique}}"
}

HTTP/1.1 201
[Captures]
initiative_alpha_id: jsonpath "$.initiativeId"

POST {{base_url}}/api/initiatives
Content-Type: application/json
Cookie: sessionToken={{session_token}}

{
  "productId": "{{product_a_id}}",
  "title": "Initiative Beta {{unique}}"
}

HTTP/1.1 201
[Captures]
initiative_beta_id: jsonpath "$.initiativeId"

# Create one under product B (should not appear in product A list)
POST {{base_url}}/api/initiatives
Content-Type: application/json
Cookie: sessionToken={{session_token}}

{
  "productId": "{{product_b_id}}",
  "title": "Initiative Gamma {{unique}}"
}

HTTP/1.1 201

# ------------------------------------------------------------
# 8. List initiatives for product A — should see 2
# ------------------------------------------------------------

GET {{base_url}}/api/initiatives?productId={{product_a_id}}
Cookie: sessionToken={{session_token}}

HTTP/1.1 200
[Asserts]
jsonpath "$.initiatives" count == 2
jsonpath "$.initiatives[0].initiativeId" == {{initiative_alpha_id}}
jsonpath "$.initiatives[0].title" contains "Initiative Alpha"
jsonpath "$.initiatives[0].progressStatus" == "thinking"
jsonpath "$.initiatives[0].lifecycleStatus" == "waiting"

# ------------------------------------------------------------
# 9. List initiatives — missing productId param
# ------------------------------------------------------------

GET {{base_url}}/api/initiatives
Cookie: sessionToken={{session_token}}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 10. List initiatives — unauthorized
# ------------------------------------------------------------

GET {{base_url}}/api/initiatives?productId={{product_a_id}}

HTTP/1.1 401

# ------------------------------------------------------------
# 11. Update initiative alpha — score, progress, lifecycle
# ------------------------------------------------------------

PUT {{base_url}}/api/initiatives/{{initiative_alpha_id}}/score
Content-Type: application/json
Cookie: sessionToken={{session_token}}

{
  "scoreType": "proxy",
  "userValue": { "value": 5 },
  "timeCriticality": { "value": 3 },
  "riskReduction": { "value": 2 },
  "effort": { "value": 3 },
  "isCore": true
}

HTTP/1.1 200

PATCH {{base_url}}/api/initiatives/{{initiative_alpha_id}}/progress-status
Content-Type: application/json
Cookie: sessionToken={{session_token}}

{
  "progressStatus": "building"
}

HTTP/1.1 200

PATCH {{base_url}}/api/initiatives/{{initiative_alpha_id}}/lifecycle-status
Content-Type: application/json
Cookie: sessionToken={{session_token}}

{
  "lifecycleStatus": "active"
}

HTTP/1.1 200

# ------------------------------------------------------------
# 12. Get initiative detail — should reflect all updates
# ------------------------------------------------------------

GET {{base_url}}/api/initiatives/{{initiative_alpha_id}}
Cookie: sessionToken={{session_token}}

HTTP/1.1 200
[Asserts]
jsonpath "$.initiative.initiativeId" == {{initiative_alpha_id}}
jsonpath "$.initiative.title" contains "Initiative Alpha"
jsonpath "$.initiative.progressStatus" == "building"
jsonpath "$.initiative.lifecycleStatus" == "active"
jsonpath "$.initiative.score.scoreType" == "proxy"
jsonpath "$.initiative.score.userValue.value" == 5
jsonpath "$.initiative.score.isCore" == true

# ------------------------------------------------------------
# 13. Get initiative — not found
# ------------------------------------------------------------

GET {{base_url}}/api/initiatives/00000000-0000-0000-0000-000000000000
Cookie: sessionToken={{session_token}}

HTTP/1.1 404

# ------------------------------------------------------------
# 14. Get initiative — unauthorized
# ------------------------------------------------------------

GET {{base_url}}/api/initiatives/{{initiative_alpha_id}}

HTTP/1.1 401

# ------------------------------------------------------------
# 15. List tasks — empty initially
# ------------------------------------------------------------

GET {{base_url}}/api/tasks?initiativeId={{initiative_alpha_id}}
Cookie: sessionToken={{session_token}}

HTTP/1.1 200
[Asserts]
jsonpath "$.tasks" count == 0

# ------------------------------------------------------------
# 16. Create tasks for initiative alpha
# ------------------------------------------------------------

POST {{base_url}}/api/tasks
Content-Type: application/json
Cookie: sessionToken={{session_token}}

{
  "title": "Task One {{unique}}",
  "kind": "initiative_task",
  "initiativeId": "{{initiative_alpha_id}}"
}

HTTP/1.1 201
[Captures]
task_one_id: jsonpath "$.taskId"

POST {{base_url}}/api/tasks
Content-Type: application/json
Cookie: sessionToken={{session_token}}

{
  "title": "Task Two {{unique}}",
  "kind": "initiative_task",
  "initiativeId": "{{initiative_alpha_id}}"
}

HTTP/1.1 201
[Captures]
task_two_id: jsonpath "$.taskId"

# ------------------------------------------------------------
# 17. List tasks for initiative — should see 2
# ------------------------------------------------------------

GET {{base_url}}/api/tasks?initiativeId={{initiative_alpha_id}}
Cookie: sessionToken={{session_token}}

HTTP/1.1 200
[Asserts]
jsonpath "$.tasks" count == 2
jsonpath "$.tasks[0].taskId" == {{task_one_id}}
jsonpath "$.tasks[0].title" contains "Task One"
jsonpath "$.tasks[0].status" == "todo"
jsonpath "$.tasks[0].kind" == "initiative_task"

# ------------------------------------------------------------
# 18. Update task status and verify in list
# ------------------------------------------------------------

PATCH {{base_url}}/api/tasks/{{task_one_id}}/status
Content-Type: application/json
Cookie: sessionToken={{session_token}}

{
  "status": "doing"
}

HTTP/1.1 200

GET {{base_url}}/api/tasks?initiativeId={{initiative_alpha_id}}
Cookie: sessionToken={{session_token}}

HTTP/1.1 200
[Asserts]
jsonpath "$.tasks[0].status" == "doing"

# ------------------------------------------------------------
# 19. List tasks — missing initiativeId param
# ------------------------------------------------------------

GET {{base_url}}/api/tasks
Cookie: sessionToken={{session_token}}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 20. List tasks — unauthorized
# ------------------------------------------------------------

GET {{base_url}}/api/tasks?initiativeId={{initiative_alpha_id}}

HTTP/1.1 401
