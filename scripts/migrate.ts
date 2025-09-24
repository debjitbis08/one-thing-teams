import { readFile, readdir } from "node:fs/promises";
import { createInterface } from "node:readline/promises";
import { join } from "node:path";
import { Client } from "pg";

import { env } from "../src/config/env";

const MIGRATIONS_DIR = join(process.cwd(), "db/migrations");
const MIGRATIONS_TABLE = "schema_migrations";

const askConfirm = async (message: string) => {
  const rl = createInterface({ input: process.stdin, output: process.stdout });
  const answer = (await rl.question(`${message} (y/N) `)).trim().toLowerCase();
  rl.close();
  return answer === "y" || answer === "yes";
};

const loadMigrations = async () => {
  const entries = await readdir(MIGRATIONS_DIR);
  return entries
    .filter(name => name.endsWith(".sql"))
    .sort()
    .map(name => ({ name, path: join(MIGRATIONS_DIR, name) }));
};

const ensureMigrationsTable = async (client: Client) => {
  await client.query(
    `CREATE TABLE IF NOT EXISTS ${MIGRATIONS_TABLE} (
      name TEXT PRIMARY KEY,
      applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )`
  );
};

const appliedMigrations = async (client: Client): Promise<Set<string>> => {
  const result = await client.query<{ name: string }>(`SELECT name FROM ${MIGRATIONS_TABLE}`);
  return new Set(result.rows.map(row => row.name));
};

const runMigration = async (client: Client, name: string, sqlText: string) => {
  await client.query("BEGIN");
  try {
    await client.query(sqlText);
    await client.query(`INSERT INTO ${MIGRATIONS_TABLE} (name) VALUES ($1)`, [name]);
    await client.query("COMMIT");
    console.log(`✔ Applied ${name}`);
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  }
};

const main = async () => {
  const migrations = await loadMigrations();
  if (migrations.length === 0) {
    console.log("No migration files found.");
    return;
  }

  const client = new Client({ connectionString: String(env.DATABASE_URL) });
  await client.connect();

  try {
    await ensureMigrationsTable(client);
    const completed = await appliedMigrations(client);
    const pending = migrations.filter(migration => !completed.has(migration.name));

    if (pending.length === 0) {
      console.log("Database is already up to date.");
      return;
    }

    console.log("Pending migrations:");
    pending.forEach(migration => console.log(` - ${migration.name}`));

    if (!(await askConfirm("Apply these migrations?"))) {
      console.log("Migration cancelled.");
      return;
    }

    for (const migration of pending) {
      const sqlText = await readFile(migration.path, "utf8");
      await runMigration(client, migration.name, sqlText);
    }

    console.log("All migrations applied successfully.");
  } finally {
    await client.end();
  }
};

main().catch(error => {
  console.error("Migration failed:", error);
  process.exit(1);
});
