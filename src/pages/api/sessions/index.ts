import type { APIRoute } from "astro";

import {
  getSessionsByUserId,
  deleteAllUserSessions,
} from "../../../contexts/id/infrastructure/SessionTokenService";

export const prerender = false;

export const GET: APIRoute = async ctx => {
  const { userId, sessionId } = ctx.locals.session!;
  const sessions = await getSessionsByUserId(userId, sessionId);

  return new Response(
    JSON.stringify({
      sessions: sessions.map(s => ({
        id: s.id,
        ipAddress: s.ipAddress,
        userAgent: s.userAgent,
        createdAt: s.createdAt.toISOString(),
        lastVerifiedAt: s.lastVerifiedAt.toISOString(),
        expiresAt: s.expiresAt.toISOString(),
        current: s.current,
      })),
    }),
    {
      status: 200,
      headers: { "Content-Type": "application/json" },
    },
  );
};

export const DELETE: APIRoute = async ctx => {
  const { userId, sessionId } = ctx.locals.session!;
  const count = await deleteAllUserSessions(userId, sessionId);

  return new Response(
    JSON.stringify({ ok: true, revokedCount: count }),
    {
      status: 200,
      headers: { "Content-Type": "application/json" },
    },
  );
};
