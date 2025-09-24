import { pino } from "pino";
import { env } from "../config/env";

export const logger = pino({
  redact: ["DATABASE_URL"],
  level: String(env.LOG_LEVEL),
  transport: {
    target: "pino-pretty",
  },
});
