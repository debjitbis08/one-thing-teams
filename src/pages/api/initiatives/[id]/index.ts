import type { APIRoute } from "astro";

import { getInitiativeById } from "../../../../contexts/pm/infrastructure/read/InitiativeReadRepository";

export const prerender = false;

export const GET: APIRoute = async ctx => {
  const session = ctx.locals.session;
  if (!session) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const initiativeId = ctx.params.id!;
  const initiative = await getInitiativeById(session.organizationId, initiativeId);

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
