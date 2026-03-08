import type { APIRoute } from "astro";

import { putJs } from "../../../../contexts/pm/web/ScoreInitiativeController.gen";
import { scoreInitiativeBridgeFactory } from "../../../../contexts/pm/infrastructure/ScoreInitiativeBridge";

export const prerender = false;

export const PUT: APIRoute = async ctx => {
  const session = ctx.locals.session!;
  const initiativeId = ctx.params.id!;
  const deps = scoreInitiativeBridgeFactory();

  const result = await putJs(deps, {
    request: ctx.request as any,
    session: session,
    initiativeId,
  } as any);

  return new Response(JSON.stringify(result.body), {
    status: result.status,
    headers: { "Content-Type": "application/json" },
  });
};
