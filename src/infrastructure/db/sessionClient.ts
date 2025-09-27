import { Pool } from "pg";
import { drizzle } from "drizzle-orm/node-postgres";

import { env } from "../../config/env";
import * as schema from "./schema";

const sessionPool = new Pool({
  connectionString: env.DATABASE_URL,
  max: env.SESSION_DB_POOL_MAX,
  idleTimeoutMillis: env.SESSION_DB_POOL_IDLE_TIMEOUT_MS,
  application_name: "one-thing-teams/session-store",
});

export const sessionDb = drizzle(sessionPool, { schema });
export const sessionConnectionPool = sessionPool;
