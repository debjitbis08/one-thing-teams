import type { APIRoute } from "astro";

import { postJs } from "../../contexts/pm/web/CreateInitiativeController.gen";
import { createInitiativeBridgeFactory } from "../../contexts/pm/infrastructure/CreateInitiativeBridge";
import { listInitiativesForProduct } from "../../contexts/pm/infrastructure/read/InitiativeReadRepository";

export const prerender = false;

export const GET: APIRoute = async ctx => {
  const session = ctx.locals.session;
  if (!session) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const productId = ctx.url.searchParams.get("productId");
  if (!productId) {
    return new Response(JSON.stringify({ error: "Query parameter 'productId' is required" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const initiatives = await listInitiativesForProduct(session.organizationId, productId);
  return new Response(JSON.stringify({ initiatives }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
};

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
