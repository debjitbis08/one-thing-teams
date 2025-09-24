import { Pool } from "pg";
import { drizzle } from "drizzle-orm/node-postgres";

import { env } from "../../config/env";
import * as schema from "./schema";

const pool = new Pool({ connectionString: String(env.DATABASE_URL) });

export const db = drizzle(pool, { schema });
export const connectionPool = pool;
