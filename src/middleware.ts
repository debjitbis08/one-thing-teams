import { defineMiddleware } from "astro/middleware";

import { getSessionFromRequest } from "./contexts/id/infrastructure/authenticateSession";
import { logger } from "./utilities/logger";

const publicApiRoutes = new Set<string>(["/api/register", "/api/login"]);

export const onRequest = defineMiddleware(async (context, next) => {
  const { pathname } = context.url;

  if (!pathname.startsWith("/api")) {
    return next();
  }

  if (publicApiRoutes.has(pathname)) {
    return next();
  }

  const session = await getSessionFromRequest(context.request);
  if (!session) {
    logger.warn({ msg: "Unauthorized API request", path: pathname });
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: {
        "Content-Type": "application/json",
      },
    });
  }

  context.locals.session = session;
  return next();
});
