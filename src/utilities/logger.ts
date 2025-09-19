import { pino } from "pino";
import { env } from "../config/env";

export const logger = pino({
    redact: ["DATABASE_CONNECTION"],
    level: String(env.LOG_LEVEL),
    transport: {
        target: "pino-pretty",
    },
});