import type { APIRoute } from "astro";

import { postJs } from "../../contexts/pm/web/CreateInitiativeController.gen";
import { createInitiativeBridgeFactory } from "../../contexts/pm/infrastructure/CreateInitiativeBridge";

export const prerender = false;

export const POST: APIRoute = async ctx => {
  const session = ctx.locals.session!;
  const deps = createInitiativeBridgeFactory(session.organizationId);

  const result = await postJs(deps, {
    request: ctx.request as any,
    session: session,
  } as any);

  return new Response(JSON.stringify(result.body), {
    status: result.status,
    headers: { "Content-Type": "application/json" },
  });
};
