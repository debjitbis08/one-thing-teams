import { Pool } from "pg";
import { drizzle } from "drizzle-orm/node-postgres";
import { v7 as uuidv7 } from "uuid";
import { hash } from "@node-rs/argon2";

import { env } from "../src/config/env";
import { events, snapshots } from "../src/infrastructure/db/schema";

const main = async () => {
  const pool = new Pool({ connectionString: String(env.DATABASE_URL) });
  const db = drizzle(pool);

  console.log("Seeding database...");

  const userId = uuidv7();
  const orgId = uuidv7();
  const password = "password123";
  const passwordHash = await hash(password);

  const userRegisteredEvent = {
    id: uuidv7(),
    orgId,
    aggregateId: userId,
    aggregateType: "user",
    version: 1,
    type: "UserRegistered",
    data: {
      userId,
      username: "admin",
      displayName: "Admin User",
      email: "admin@example.com",
      passwordHash,
    },
    meta: {},
  };

  const orgCreatedEvent = {
    id: uuidv7(),
    orgId,
    aggregateId: orgId,
    aggregateType: "organization",
    version: 1,
    type: "OrganizationCreated",
    data: {
      organizationId: orgId,
      name: "Default Organization",
      createdBy: userId,
    },
    meta: {},
  };

  const userSnapshot = {
    aggregateId: userId,
    aggregateType: "user",
    orgId,
    version: 1,
    state: {
      userId,
      username: "admin",
      displayName: "Admin User",
      email: "admin@example.com",
      status: "ACTIVE",
      passwordProvider: { passwordHash },
      memberships: [
        {
          organizationId: orgId,
          organizationName: "Default Organization",
          roles: ["OWNER"],
        },
      ],
      preferredOrganization: orgId,
      isContributor: false,
    },
  };

  await db.insert(events).values([userRegisteredEvent, orgCreatedEvent]);
  await db.insert(snapshots).values([userSnapshot]);

  // Refresh the materialized view
  await pool.query("REFRESH MATERIALIZED VIEW CONCURRENTLY latest_snapshots");

  console.log("Seed complete.");
  console.log(`  User: admin@example.com / ${password}`);
  console.log(`  Org:  Default Organization (${orgId})`);

  await pool.end();
};

main().catch(error => {
  console.error("Seed failed:", error);
  process.exit(1);
});
