import type { APIRoute } from "astro";

import { deleteJs } from "../../../../../contexts/pm/web/ScenarioController.gen";
import { removeScenarioBridgeFactory } from "../../../../../contexts/pm/infrastructure/ScenarioBridge";

export const prerender = false;

export const DELETE: APIRoute = async ctx => {
  const session = ctx.locals.session!;
  const taskId = ctx.params.taskId!;
  const scenarioId = ctx.params.scenarioId!;
  const deps = removeScenarioBridgeFactory();

  const result = await deleteJs(deps, {
    session: session,
    taskId,
    scenarioId,
  } as any);

  return new Response(JSON.stringify(result.body), {
    status: result.status,
    headers: { "Content-Type": "application/json" },
  });
};
