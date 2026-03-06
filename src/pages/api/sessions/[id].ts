import type { APIRoute } from "astro";

import {
  getSessionsByUserId,
  deleteSession,
} from "../../../contexts/id/infrastructure/SessionTokenService";

export const prerender = false;

export const DELETE: APIRoute = async ctx => {
  const targetSessionId = ctx.params.id;
  if (!targetSessionId) {
    return new Response(JSON.stringify({ error: "Session ID is required" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const { userId, sessionId } = ctx.locals.session!;

  // Verify the target session belongs to this user
  const sessions = await getSessionsByUserId(userId, sessionId);
  const target = sessions.find(s => s.id === targetSessionId);
  if (!target) {
    return new Response(JSON.stringify({ error: "Session not found" }), {
      status: 404,
      headers: { "Content-Type": "application/json" },
    });
  }

  if (target.current) {
    return new Response(
      JSON.stringify({ error: "Use POST /api/logout to revoke the current session" }),
      {
        status: 400,
        headers: { "Content-Type": "application/json" },
      },
    );
  }

  await deleteSession(targetSessionId);

  return new Response(JSON.stringify({ ok: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
};
