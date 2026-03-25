import type { APIRoute } from "astro";

import { postJs } from "../../contexts/pm/web/CreateTaskController.gen";
import { createTaskBridgeFactory } from "../../contexts/pm/infrastructure/CreateTaskBridge";
import { listTasksForInitiative } from "../../contexts/pm/infrastructure/read/TaskReadRepository";

export const prerender = false;

export const GET: APIRoute = async ctx => {
  const session = ctx.locals.session;
  if (!session) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const initiativeId = ctx.url.searchParams.get("initiativeId");
  if (!initiativeId) {
    return new Response(JSON.stringify({ error: "Query parameter 'initiativeId' is required" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const tasks = await listTasksForInitiative(session.organizationId, initiativeId);
  return new Response(JSON.stringify({ tasks }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
};

export const POST: APIRoute = async ctx => {
  const session = ctx.locals.session!;
  const deps = createTaskBridgeFactory(session.organizationId);

  const result = await postJs(deps, {
    request: ctx.request as any,
    session: session,
  } as any);

  return new Response(JSON.stringify(result.body), {
    status: result.status,
    headers: { "Content-Type": "application/json" },
  });
};
