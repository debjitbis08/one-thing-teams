import type { APIRoute } from "astro";

import { deleteAssignJs } from "../../../../../contexts/pm/web/TaskController.gen";
import { unassignTaskBridgeFactory } from "../../../../../contexts/pm/infrastructure/TaskBridge";

export const prerender = false;

export const DELETE: APIRoute = async ctx => {
  const session = ctx.locals.session!;
  const taskId = ctx.params.taskId!;
  const userId = ctx.params.userId!;
  const deps = unassignTaskBridgeFactory();

  const result = await deleteAssignJs(deps, {
    session: session,
    taskId,
    userId,
  } as any);

  return new Response(JSON.stringify(result.body), {
    status: result.status,
    headers: { "Content-Type": "application/json" },
  });
};
