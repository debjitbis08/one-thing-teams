import crypto from "crypto";
import { eq, lt } from "drizzle-orm";

import { env } from "../../../config/env";
import { identitySessions } from "../../../infrastructure/db/schema";
import { sessionDb } from "../../../infrastructure/db/sessionClient";

const SESSION_ID_ALPHABET = "abcdefghijkmnpqrstuvwxyz23456789";
const SESSION_ID_BYTES = 24;

const sessionJwtSecret = (() => {
  try {
    const decoded = Buffer.from(env.SESSION_JWT_SECRET, "base64");
    if (decoded.length >= 32) {
      return decoded;
    }
  } catch (_) {
    // ignore, fallback to utf-8
  }
  const utf8 = Buffer.from(env.SESSION_JWT_SECRET, "utf-8");
  if (utf8.length < 32) {
    throw new Error("SESSION_JWT_SECRET must be at least 32 bytes when decoded");
  }
  return utf8;
})();

const sessionTtlMs = env.SESSION_TOKEN_TTL_SECONDS * 1000;
const sessionJwtTtlMs = env.SESSION_JWT_TTL_SECONDS * 1000;
const activityUpdateIntervalMs = env.SESSION_ACTIVITY_UPDATE_INTERVAL_SECONDS * 1000;

export type IssueSessionTokensInput = {
  userId: string;
  organizationId: string;
  roles: string[];
};

export type IssuedSessionTokens = {
  sessionToken: string;
  sessionTokenExpiresAt: string;
  sessionJwt: string;
  sessionJwtExpiresAt: string;
};

export type AuthenticatedSession = {
  sessionId: string;
  userId: string;
  organizationId: string;
  roles: string[];
};

export async function issueSessionTokens(
  input: IssueSessionTokensInput,
): Promise<IssuedSessionTokens> {
  const now = new Date();
  const sessionId = generateRandomString();
  const sessionSecret = generateRandomString();
  const sessionToken = `${sessionId}.${sessionSecret}`;
  const sessionTokenExpiresAt = new Date(now.getTime() + sessionTtlMs);
  const sessionJwtExpiresAt = new Date(now.getTime() + sessionJwtTtlMs);

  const secretHash = hashSecret(sessionSecret);

  await sessionDb.insert(identitySessions).values({
    id: sessionId,
    userId: input.userId,
    organizationId: input.organizationId,
    roles: input.roles,
    secretHash,
    lastVerifiedAt: now,
    createdAt: now,
    expiresAt: sessionTokenExpiresAt,
  });

  const sessionJwt = createSessionJwt({
    sessionId,
    userId: input.userId,
    organizationId: input.organizationId,
    roles: input.roles,
    createdAt: now,
    expiresAt: sessionJwtExpiresAt,
  });

  return {
    sessionToken,
    sessionTokenExpiresAt: sessionTokenExpiresAt.toISOString(),
    sessionJwt,
    sessionJwtExpiresAt: sessionJwtExpiresAt.toISOString(),
  };
}

export function validateSessionJwt(token: string): AuthenticatedSession | null {
  try {
    const parts = token.split(".");
    if (parts.length !== 3) {
      return null;
    }

    const [headerPart, payloadPart, signaturePart] = parts;
    const data = `${headerPart}.${payloadPart}`;
    const expectedSignature = base64UrlEncode(
      crypto.createHmac("sha256", sessionJwtSecret).update(data).digest(),
    );

    if (!timingSafeEqualBase64(signaturePart, expectedSignature)) {
      return null;
    }

    const payloadJson = base64UrlDecode(payloadPart).toString("utf-8");
    const payload = JSON.parse(payloadJson) as {
      session?: {
        id?: string;
        user_id?: string;
        organization_id?: string;
        roles?: unknown;
        created_at?: number;
      };
      iat?: number;
      exp?: number;
    };

    if (!payload.session) {
      return null;
    }

    const { id, user_id, organization_id, roles } = payload.session;
    if (!id || !user_id || !organization_id || !Array.isArray(roles)) {
      return null;
    }

    if (typeof payload.exp !== "number" || payload.exp * 1000 <= Date.now()) {
      return null;
    }

    const normalizedRoles = roles.every(role => typeof role === "string")
      ? (roles as string[])
      : null;
    if (!normalizedRoles) {
      return null;
    }

    return {
      sessionId: id,
      userId: user_id,
      organizationId: organization_id,
      roles: normalizedRoles,
    };
  } catch (_) {
    return null;
  }
}

export async function validateSessionToken(
  token: string,
): Promise<AuthenticatedSession | null> {
  const parts = token.split(".");
  if (parts.length !== 2) {
    return null;
  }
  const [sessionId, providedSecret] = parts;
  if (!sessionId || !providedSecret) {
    return null;
  }

  const rows = await sessionDb
    .select()
    .from(identitySessions)
    .where(eq(identitySessions.id, sessionId))
    .limit(1);

  const session = rows[0];
  if (!session) {
    return null;
  }

  if (new Date(session.expiresAt).getTime() <= Date.now()) {
    await deleteSession(sessionId);
    return null;
  }

  const providedHash = hashSecret(providedSecret);
  if (!timingSafeEqualHex(session.secretHash, providedHash)) {
    return null;
  }

  if (shouldUpdateActivity(new Date(session.lastVerifiedAt))) {
    await sessionDb
      .update(identitySessions)
      .set({ lastVerifiedAt: new Date() })
      .where(eq(identitySessions.id, sessionId));
  }

  return {
    sessionId,
    userId: session.userId,
    organizationId: session.organizationId,
    roles: session.roles,
  };
}

export async function deleteSession(sessionId: string): Promise<void> {
  await sessionDb.delete(identitySessions).where(eq(identitySessions.id, sessionId));
}

export async function cleanupExpiredSessions(): Promise<number> {
  const result = await sessionDb
    .delete(identitySessions)
    .where(lt(identitySessions.expiresAt, new Date()))
    .returning({ id: identitySessions.id });
  return result.length;
}

function shouldUpdateActivity(lastVerifiedAt: Date): boolean {
  return Date.now() - lastVerifiedAt.getTime() >= activityUpdateIntervalMs;
}

function generateRandomString(): string {
  const bytes = crypto.randomBytes(SESSION_ID_BYTES);
  let output = "";
  for (const byte of bytes) {
    output += SESSION_ID_ALPHABET[byte >> 3];
  }
  return output;
}

function hashSecret(secret: string): string {
  return crypto.createHash("sha256").update(secret).digest("hex");
}

function createSessionJwt(params: {
  sessionId: string;
  userId: string;
  organizationId: string;
  roles: string[];
  createdAt: Date;
  expiresAt: Date;
}): string {
  const header = base64UrlEncode(Buffer.from(JSON.stringify({ alg: "HS256", typ: "JWT" })));
  const payload = base64UrlEncode(
    Buffer.from(
      JSON.stringify({
        session: {
          id: params.sessionId,
          user_id: params.userId,
          organization_id: params.organizationId,
          roles: params.roles,
          created_at: Math.floor(params.createdAt.getTime() / 1000),
        },
        iat: Math.floor(params.createdAt.getTime() / 1000),
        exp: Math.floor(params.expiresAt.getTime() / 1000),
      }),
    ),
  );
  const data = `${header}.${payload}`;
  const signature = base64UrlEncode(crypto.createHmac("sha256", sessionJwtSecret).update(data).digest());
  return `${data}.${signature}`;
}

function base64UrlEncode(buffer: Buffer): string {
  return buffer
    .toString("base64")
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
}

function base64UrlDecode(value: string): Buffer {
  const normalized = value.replace(/-/g, "+").replace(/_/g, "/");
  const padded = normalized.padEnd(normalized.length + ((4 - (normalized.length % 4)) % 4), "=");
  return Buffer.from(padded, "base64");
}

function timingSafeEqualHex(storedHex: string, providedHex: string): boolean {
  const stored = Buffer.from(storedHex, "hex");
  const provided = Buffer.from(providedHex, "hex");
  if (stored.length !== provided.length) {
    return false;
  }
  return crypto.timingSafeEqual(stored, provided);
}

function timingSafeEqualBase64(a: string, b: string): boolean {
  const bufferA = base64UrlDecode(a);
  const bufferB = base64UrlDecode(b);
  if (bufferA.length !== bufferB.length) {
    return false;
  }
  try {
    return crypto.timingSafeEqual(bufferA, bufferB);
  } catch (_) {
    return false;
  }
}
