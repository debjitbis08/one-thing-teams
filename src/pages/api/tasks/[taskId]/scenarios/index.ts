import type { APIRoute } from "astro";

import { postJs } from "../../../../../contexts/pm/web/ScenarioController.gen";
import { addScenarioBridgeFactory } from "../../../../../contexts/pm/infrastructure/ScenarioBridge";

export const prerender = false;

export const POST: APIRoute = async ctx => {
  const session = ctx.locals.session!;
  const taskId = ctx.params.taskId!;
  const deps = addScenarioBridgeFactory();

  const result = await postJs(deps, {
    request: ctx.request as any,
    session: session,
    taskId,
  } as any);

  return new Response(JSON.stringify(result.body), {
    status: result.status,
    headers: { "Content-Type": "application/json" },
  });
};
