import { Pool } from "pg";
import { drizzle } from "drizzle-orm/node-postgres";
import { migrate } from "drizzle-orm/node-postgres/migrator";

import { env } from "../src/config/env";

const main = async () => {
  const pool = new Pool({ connectionString: String(env.DATABASE_URL) });
  const db = drizzle(pool);

  console.log("Running migrations...");
  await migrate(db, { migrationsFolder: "./drizzle" });
  console.log("Migrations applied successfully.");

  await pool.end();
};

main().catch(error => {
  console.error("Migration failed:", error);
  process.exit(1);
});
