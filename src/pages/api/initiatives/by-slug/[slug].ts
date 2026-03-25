import type { APIRoute } from "astro";

import { getInitiativeBySlug } from "../../../../contexts/pm/infrastructure/read/InitiativeReadRepository";

export const prerender = false;

export const GET: APIRoute = async ctx => {
  const session = ctx.locals.session;
  if (!session) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const slug = ctx.params.slug!;
  const productId = ctx.url.searchParams.get("productId");
  if (!productId) {
    return new Response(JSON.stringify({ error: "Query parameter 'productId' is required" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const initiative = await getInitiativeBySlug(session.organizationId, productId, slug);

  if (!initiative) {
    return new Response(JSON.stringify({ error: "Initiative not found" }), {
      status: 404,
      headers: { "Content-Type": "application/json" },
    });
  }

  return new Response(JSON.stringify({ initiative }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
};
