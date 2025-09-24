import { defineConfig } from "drizzle-kit";
import { env } from "./src/config/env";

const connectionString = String(env.DATABASE_URL);

export default defineConfig({
  schema: "./src/infrastructure/db/schema.ts",
  out: "./drizzle",
  dialect: "postgresql",
  dbCredentials: {
    url: connectionString,
  },
});
