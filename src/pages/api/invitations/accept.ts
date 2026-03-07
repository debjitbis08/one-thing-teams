import type { APIRoute } from "astro";

import { postJs } from "../../../contexts/id/web/AcceptInvitationController.gen";
import { acceptInvitationDependencies } from "../../../contexts/id/infrastructure/AcceptInvitationBridge";

export const prerender = false;

export const POST: APIRoute = async ctx => {
  const result = await postJs(acceptInvitationDependencies, {
    request: ctx.request as any,
    session: ctx.locals.session,
  } as any);

  return new Response(JSON.stringify(result.body), {
    status: result.status,
    headers: { "Content-Type": "application/json" },
  });
};
