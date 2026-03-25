import { defineMiddleware } from "astro/middleware";

import { getSessionFromRequest } from "./contexts/id/infrastructure/authenticateSession";
import { logger } from "./utilities/logger";

const publicApiRoutes = new Set<string>(["/api/register", "/api/login"]);
const publicPageRoutes = new Set<string>(["/login", "/register"]);

export const onRequest = defineMiddleware(async (context, next) => {
  const { pathname } = context.url;

  // Public pages — no auth needed
  if (publicPageRoutes.has(pathname)) {
    return next();
  }

  // Public API routes — no auth needed
  if (pathname.startsWith("/api") && publicApiRoutes.has(pathname)) {
    return next();
  }

  // Try to load session for all other routes
  const session = await getSessionFromRequest(context.request);

  if (pathname.startsWith("/api")) {
    // API routes: reject unauthorized requests
    if (!session) {
      logger.warn({ msg: "Unauthorized API request", path: pathname });
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }
  }

  // Set session for both page and API routes
  if (session) {
    context.locals.session = session;
  }

  return next();
});
