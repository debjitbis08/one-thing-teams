import { validateSessionJwt, validateSessionToken } from "./SessionTokenService";
import { logger } from "../../../utilities/logger";

export type AuthenticatedSession = {
  sessionId: string;
  userId: string;
  organizationId: string;
  roles: string[];
};

const AUTH_HEADER = "authorization";
const COOKIE_HEADER = "cookie";
const BEARER_PREFIX = "bearer ";
const SESSION_TOKEN_COOKIE = "sessionToken";
const SESSION_JWT_COOKIE = "sessionJwt";

export async function getSessionFromRequest(request: Request): Promise<AuthenticatedSession | null> {
  const bearerToken = extractBearerToken(request);
  if (bearerToken) {
    const jwtSession = validateSessionJwt(bearerToken);
    if (jwtSession) {
      return jwtSession;
    }
    logger.warn({ msg: "Invalid bearer session JWT", tokenPreview: bearerToken.slice(0, 8) });
  }

  const cookies = parseCookies(request.headers.get(COOKIE_HEADER));

  const cookieJwt = cookies.get(SESSION_JWT_COOKIE);
  if (cookieJwt) {
    const jwtSession = validateSessionJwt(cookieJwt);
    if (jwtSession) {
      return jwtSession;
    }
    logger.warn({ msg: "Invalid cookie session JWT", tokenPreview: cookieJwt.slice(0, 8) });
  }

  const sessionToken = cookies.get(SESSION_TOKEN_COOKIE);
  if (!sessionToken) {
    logger.warn({ msg: "Missing session credentials" });
    return null;
  }

  const session = await validateSessionToken(sessionToken);
  if (!session) {
    logger.warn({ msg: "Invalid session token", tokenPreview: sessionToken.slice(0, 6) });
    return null;
  }

  return session;
}

function extractBearerToken(request: Request): string | null {
  const header = request.headers.get(AUTH_HEADER);
  if (header) {
    const lower = header.toLowerCase();
    if (lower.startsWith(BEARER_PREFIX)) {
      return header.slice(BEARER_PREFIX.length).trim();
    }
  }

  return null;
}

function parseCookies(headerValue: string | null): Map<string, string> {
  const result = new Map<string, string>();
  if (!headerValue) {
    return result;
  }

  const segments = headerValue.split(";");
  for (const segment of segments) {
    const trimmed = segment.trim();
    if (!trimmed) {
      continue;
    }
    const [rawName, ...rawValueParts] = trimmed.split("=");
    if (!rawName) {
      continue;
    }
    const value = rawValueParts.join("=");
    if (!value) {
      continue;
    }
    try {
      result.set(rawName, decodeURIComponent(value));
    } catch (_) {
      result.set(rawName, value);
    }
  }

  return result;
}
