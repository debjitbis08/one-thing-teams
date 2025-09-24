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
});

console.log(env)