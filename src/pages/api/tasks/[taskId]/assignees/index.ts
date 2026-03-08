import type { APIRoute } from "astro";

import { postAssignJs } from "../../../../../contexts/pm/web/TaskController.gen";
import { assignTaskBridgeFactory } from "../../../../../contexts/pm/infrastructure/TaskBridge";

export const prerender = false;

export const POST: APIRoute = async ctx => {
  const session = ctx.locals.session!;
  const taskId = ctx.params.taskId!;
  const deps = assignTaskBridgeFactory(session.organizationId);

  const result = await postAssignJs(deps, {
    request: ctx.request as any,
    session: session,
    taskId,
  } as any);

  return new Response(JSON.stringify(result.body), {
    status: result.status,
    headers: { "Content-Type": "application/json" },
  });
};
