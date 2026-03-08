import type { APIRoute } from "astro";

import { patchProgressJs } from "../../../../contexts/pm/web/InitiativeStatusController.gen";
import { updateProgressStatusBridgeFactory } from "../../../../contexts/pm/infrastructure/InitiativeStatusBridge";

export const prerender = false;

export const PATCH: APIRoute = async ctx => {
  const session = ctx.locals.session!;
  const initiativeId = ctx.params.id!;
  const deps = updateProgressStatusBridgeFactory();

  const result = await patchProgressJs(deps, {
    request: ctx.request as any,
    session: session,
    initiativeId,
  } as any);

  return new Response(JSON.stringify(result.body), {
    status: result.status,
    headers: { "Content-Type": "application/json" },
  });
};
