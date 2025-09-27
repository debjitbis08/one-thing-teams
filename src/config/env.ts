import "dotenv/config";
import { parseEnv } from "znv";
import { z } from "zod";

export const env = parseEnv(process.env, {
  HOST: z.string().default(() => "0.0.0.0"),
  PORT: z.coerce.number().default(() => 8080),
  DATABASE_URL: z.string(),
  LOG_LEVEL: z
    .enum(["fatal", "error", "warn", "info", "debug", "trace", "silent"])
    .default("info"),
  SESSION_JWT_SECRET: z.string(),
  SESSION_JWT_TTL_SECONDS: z.coerce.number().int().positive().default(() => 60 * 5),
  SESSION_TOKEN_TTL_SECONDS: z.coerce.number().int().positive().default(() => 60 * 60 * 24 * 30),
  SESSION_ACTIVITY_UPDATE_INTERVAL_SECONDS: z
    .coerce.number()
    .int()
    .positive()
    .default(() => 60 * 60),
  SESSION_DB_POOL_MAX: z.coerce.number().int().positive().max(100).optional(),
  SESSION_DB_POOL_IDLE_TIMEOUT_MS: z.coerce.number().int().nonnegative().optional(),
});
