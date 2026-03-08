import type { APIRoute } from "astro";

import { patchTaskJs } from "../../../../contexts/pm/web/TaskController.gen";
import { updateTaskBridgeFactory } from "../../../../contexts/pm/infrastructure/TaskBridge";

export const prerender = false;

export const PATCH: APIRoute = async ctx => {
  const session = ctx.locals.session!;
  const taskId = ctx.params.taskId!;
  const deps = updateTaskBridgeFactory();

  const result = await patchTaskJs(deps, {
    request: ctx.request as any,
    session: session,
    taskId,
  } as any);

  return new Response(JSON.stringify(result.body), {
    status: result.status,
    headers: { "Content-Type": "application/json" },
  });
};
