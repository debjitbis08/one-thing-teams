# ============================================================
# Manage Tasks Integration Tests
# (status transitions, update details, assign/unassign)
# ============================================================

# ------------------------------------------------------------
# 1. Setup: Register, login, create product, initiative & task
# ------------------------------------------------------------

POST {{base_url}}/api/register
Content-Type: application/json

{
  "email": "{{email}}",
  "username": "{{username}}",
  "displayName": "Task Mgmt User {{unique}}",
  "password": "{{password}}",
  "confirmPassword": "{{password}}",
  "initialOrganizationName": "Task Mgmt Org {{unique}}"
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
  "name": "Task Mgmt Product {{unique}}"
}

HTTP/1.1 201
[Captures]
product_id: jsonpath "$.productId"

POST {{base_url}}/api/initiatives
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "productId": "{{product_id}}",
  "title": "Task Mgmt Initiative {{unique}}"
}

HTTP/1.1 201
[Captures]
initiative_id: jsonpath "$.initiativeId"

POST {{base_url}}/api/tasks
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "title": "Implement feature X {{unique}}",
  "kind": "initiative_task",
  "initiativeId": "{{initiative_id}}"
}

HTTP/1.1 201
[Captures]
task_id: jsonpath "$.taskId"

# ------------------------------------------------------------
# 2. Update task status: todo -> doing
# ------------------------------------------------------------

PATCH {{base_url}}/api/tasks/{{task_id}}/status
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "status": "doing"
}

HTTP/1.1 200
[Asserts]
jsonpath "$.success" == true

# ------------------------------------------------------------
# 3. Update task status: doing -> stuck
# ------------------------------------------------------------

PATCH {{base_url}}/api/tasks/{{task_id}}/status
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "status": "stuck"
}

HTTP/1.1 200
[Asserts]
jsonpath "$.success" == true

# ------------------------------------------------------------
# 4. Update task status: stuck -> done
# ------------------------------------------------------------

PATCH {{base_url}}/api/tasks/{{task_id}}/status
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "status": "done"
}

HTTP/1.1 200
[Asserts]
jsonpath "$.success" == true

# ------------------------------------------------------------
# 5. Invalid transition: done -> todo (not allowed)
# ------------------------------------------------------------

PATCH {{base_url}}/api/tasks/{{task_id}}/status
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "status": "todo"
}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 6. Invalid status value
# ------------------------------------------------------------

PATCH {{base_url}}/api/tasks/{{task_id}}/status
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "status": "invalid_status"
}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 7. Update task status without auth
# ------------------------------------------------------------

PATCH {{base_url}}/api/tasks/{{task_id}}/status
Content-Type: application/json

{
  "status": "doing"
}

HTTP/1.1 401
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 8. Update task title
# ------------------------------------------------------------

PATCH {{base_url}}/api/tasks/{{task_id}}
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "title": "Updated feature X {{unique}}"
}

HTTP/1.1 200
[Asserts]
jsonpath "$.success" == true

# ------------------------------------------------------------
# 9. Update task description
# ------------------------------------------------------------

PATCH {{base_url}}/api/tasks/{{task_id}}
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "description": "This is the updated description"
}

HTTP/1.1 200
[Asserts]
jsonpath "$.success" == true

# ------------------------------------------------------------
# 10. Update task with no changes - should fail
# ------------------------------------------------------------

PATCH {{base_url}}/api/tasks/{{task_id}}
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 11. Update task without auth
# ------------------------------------------------------------

PATCH {{base_url}}/api/tasks/{{task_id}}
Content-Type: application/json

{
  "title": "Should not work"
}

HTTP/1.1 401
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 12. Assign user to task
# ------------------------------------------------------------

POST {{base_url}}/api/tasks/{{task_id}}/assignees
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "userId": "{{owner_user_id}}"
}

HTTP/1.1 200
[Asserts]
jsonpath "$.success" == true

# ------------------------------------------------------------
# 13. Assign non-existent member - should fail
# ------------------------------------------------------------

POST {{base_url}}/api/tasks/{{task_id}}/assignees
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "userId": "00000000-0000-0000-0000-000000000000"
}

HTTP/1.1 404
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 14. Assign without auth - should fail
# ------------------------------------------------------------

POST {{base_url}}/api/tasks/{{task_id}}/assignees
Content-Type: application/json

{
  "userId": "{{owner_user_id}}"
}

HTTP/1.1 401
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 15. Unassign user from task
# ------------------------------------------------------------

DELETE {{base_url}}/api/tasks/{{task_id}}/assignees/{{owner_user_id}}
Cookie: sessionToken={{owner_session_token}}

HTTP/1.1 200
[Asserts]
jsonpath "$.success" == true

# ------------------------------------------------------------
# 16. Unassign without auth - should fail
# ------------------------------------------------------------

DELETE {{base_url}}/api/tasks/{{task_id}}/assignees/{{owner_user_id}}

HTTP/1.1 401
[Asserts]
jsonpath "$.error" exists

# ------------------------------------------------------------
# 17. Prune a new task (todo -> pruned)
# ------------------------------------------------------------

POST {{base_url}}/api/tasks
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "title": "Task to prune {{unique}}",
  "kind": "initiative_task",
  "initiativeId": "{{initiative_id}}"
}

HTTP/1.1 201
[Captures]
prune_task_id: jsonpath "$.taskId"

PATCH {{base_url}}/api/tasks/{{prune_task_id}}/status
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "status": "pruned"
}

HTTP/1.1 200
[Asserts]
jsonpath "$.success" == true

# ------------------------------------------------------------
# 18. Update status on non-existent task - should fail
# ------------------------------------------------------------

PATCH {{base_url}}/api/tasks/00000000-0000-0000-0000-000000000000/status
Content-Type: application/json
Cookie: sessionToken={{owner_session_token}}

{
  "status": "doing"
}

HTTP/1.1 404
[Asserts]
jsonpath "$.error" exists
