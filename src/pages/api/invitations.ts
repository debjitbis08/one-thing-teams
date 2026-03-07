import type { APIRoute } from "astro";

import { postJs } from "../../contexts/id/web/CreateInvitationController.gen";
import { createInvitationDependencies } from "../../contexts/id/infrastructure/CreateInvitationBridge";
import { listPendingInvitations } from "../../contexts/id/infrastructure/InvitationAggregateLoader";

export const prerender = false;

export const POST: APIRoute = async ctx => {
  const result = await postJs(createInvitationDependencies, {
    request: ctx.request as any,
    session: ctx.locals.session,
  } as any);

  return new Response(JSON.stringify(result.body), {
    status: result.status,
    headers: { "Content-Type": "application/json" },
  });
};

export const GET: APIRoute = async ctx => {
  const session = ctx.locals.session;
  if (!session) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const roles = session.roles as string[];
  const isAllowed = roles.some(r => r === "OWNER" || r === "ADMIN");
  if (!isAllowed) {
    return new Response(JSON.stringify({ error: "Forbidden" }), {
      status: 403,
      headers: { "Content-Type": "application/json" },
    });
  }

  const invitations = await listPendingInvitations(session.organizationId);

  return new Response(JSON.stringify({ invitations }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
};
