#!/usr/bin/env node

import { PostgreSqlContainer } from "@testcontainers/postgresql";
import { Client } from "pg";
import { readFile, readdir } from "node:fs/promises";
import { join } from "node:path";

const MIGRATIONS_DIR = join(process.cwd(), "db/migrations");

async function loadMigrations() {
  const entries = await readdir(MIGRATIONS_DIR);
  return entries
    .filter((name) => name.endsWith(".sql"))
    .sort()
    .map((name) => ({ name, path: join(MIGRATIONS_DIR, name) }));
}

async function applyMigrations(client: Client, migrations: Array<{ name: string; path: string }>) {
  for (const migration of migrations) {
    const sqlText = await readFile(migration.path, "utf8");
    try {
      await client.query(sqlText);
      console.log(`  ✓ Applied ${migration.name}`);
    } catch (error) {
      console.error(`  ✗ Failed to apply ${migration.name}:`, error);
      throw error;
    }
  }
}

async function main() {
  try {
    console.log("Starting PostgreSQL test container...");

    const container = await new PostgreSqlContainer("postgres:17-alpine")
      .withStartupTimeout(60000)
      .start();

    const connectionString = container.getConnectionUri();
    console.log(`✓ Container started`);

    console.log("Running migrations...");
    const client = new Client({ connectionString });
    await client.connect();

    try {
      const migrations = await loadMigrations();
      await applyMigrations(client, migrations);
      console.log(`✓ Applied ${migrations.length} migrations`);
    } finally {
      await client.end();
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
