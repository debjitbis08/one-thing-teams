import { parseEnv } from "znv";
import { z } from "zod";
import "dotenv/config";

export const env = parseEnv(process.env, {
    HOST: z.string().default("0.0.0.0"),
    PORT: z.number().default(8080),
    DATABASE_CONNECTION: z.string(), // postgres://username:password@host:port/database
    LOG_LEVEL: z
        .enum(["fatal", "error", "warn", "info", "debug", "trace", "silent"])
        .default("info"),
});