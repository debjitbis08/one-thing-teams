import type { APIRoute } from "astro";

import { deleteJs } from "../../../contexts/id/web/RevokeInvitationController.gen";
import { revokeInvitationDependencies } from "../../../contexts/id/infrastructure/RevokeInvitationBridge";

export const prerender = false;

export const DELETE: APIRoute = async ctx => {
  const invitationId = ctx.params.id;
  if (!invitationId) {
    return new Response(JSON.stringify({ error: "Invitation ID is required" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const result = await deleteJs(revokeInvitationDependencies, {
    session: ctx.locals.session,
    invitationId,
  } as any);

  return new Response(JSON.stringify(result.body), {
    status: result.status,
    headers: { "Content-Type": "application/json" },
  });
};
