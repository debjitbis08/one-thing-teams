#!/usr/bin/env node

import { PostgreSqlContainer } from "@testcontainers/postgresql";
import { Pool } from "pg";
import { drizzle } from "drizzle-orm/node-postgres";
import { migrate } from "drizzle-orm/node-postgres/migrator";

async function main() {
  try {
    console.log("Starting PostgreSQL test container...");

    const container = await new PostgreSqlContainer("postgres:17-alpine")
      .withStartupTimeout(60000)
      .start();

    const connectionString = container.getConnectionUri();
    console.log(`✓ Container started`);

    console.log("Running migrations...");
    const pool = new Pool({ connectionString });
    const db = drizzle(pool);

    try {
      await migrate(db, { migrationsFolder: "./drizzle" });
      console.log(`✓ Migrations applied`);
    } finally {
      await pool.end();
    }

    // Output the connection string for the shell script to capture
    console.log(`\nCONNECTION_STRING=${connectionString}`);
    console.log("READY");

    // Keep container running if explicitly requested
    if (process.env.KEEP_CONTAINER === "1") {
      console.log("\nContainer is ready. Keeping it running for tests...");
      process.on("SIGINT", async () => {
        console.log("\nStopping container...");
        await container.stop();
        process.exit(0);
      });
      await new Promise(() => {});
    }
  } catch (error) {
    console.error("Failed to setup test database:", error);
    process.exit(1);
  }
}

main();
