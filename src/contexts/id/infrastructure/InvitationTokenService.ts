import crypto from "crypto";

const TOKEN_BYTES = 32;

export function generateInvitationToken(): string {
  return crypto.randomBytes(TOKEN_BYTES).toString("base64url");
}

export function hashInvitationToken(token: string): string {
  return crypto.createHash("sha256").update(token).digest("hex");
}
