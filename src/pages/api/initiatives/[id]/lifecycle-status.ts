import type { APIRoute } from "astro";

import { patchLifecycleJs } from "../../../../contexts/pm/web/InitiativeStatusController.gen";
import { updateLifecycleStatusBridgeFactory } from "../../../../contexts/pm/infrastructure/InitiativeStatusBridge";

export const prerender = false;

export const PATCH: APIRoute = async ctx => {
  const session = ctx.locals.session!;
  const initiativeId = ctx.params.id!;
  const deps = updateLifecycleStatusBridgeFactory();

  const result = await patchLifecycleJs(deps, {
    request: ctx.request as any,
    session: session,
    initiativeId,
  } as any);

  return new Response(JSON.stringify(result.body), {
    status: result.status,
    headers: { "Content-Type": "application/json" },
  });
};
