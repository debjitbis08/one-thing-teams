import type { APIRoute } from "astro";

import { deleteSession } from "../../contexts/id/infrastructure/SessionTokenService";

export const prerender = false;

export const POST: APIRoute = async ctx => {
  const { sessionId } = ctx.locals.session!;
  await deleteSession(sessionId);

  return new Response(JSON.stringify({ ok: true }), {
    status: 200,
    headers: {
      "Content-Type": "application/json",
      "Set-Cookie": [
        "sessionToken=; Path=/; Max-Age=0; HttpOnly; SameSite=Lax",
        "sessionJwt=; Path=/; Max-Age=0; HttpOnly; SameSite=Lax",
      ].join(", "),
    },
  });
};
