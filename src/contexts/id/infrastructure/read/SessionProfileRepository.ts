import { sql } from "drizzle-orm";

import { db } from "../../../../infrastructure/db/client";

export type SessionProfile = {
  displayName: string;
  email: string;
  organizationName: string;
};

export async function getSessionProfile(
  userId: string,
  organizationId: string,
): Promise<SessionProfile | null> {
  // Get user display name and email from user snapshot
  const userResult = await db.execute(sql<{
    display_name: string;
    email: string;
  }>`
    SELECT
      state->'user'->>'displayName' AS display_name,
      state->'user'->>'email' AS email
    FROM "snapshots"
    WHERE aggregate_id = ${userId}
      AND aggregate_type = 'identity.user'
    ORDER BY version DESC
    LIMIT 1
  `);

  const userRow = userResult.rows[0] as { display_name: string; email: string } | undefined;
  if (!userRow) return null;

  // Get organization name from org events
  const orgResult = await db.execute(sql<{
    name: string;
  }>`
    SELECT data->>'name' AS name
    FROM "events"
    WHERE aggregate_id = ${organizationId}
      AND aggregate_type = 'identity.organization'
      AND type IN ('identity.organization.created', 'identity.organization.renamed')
    ORDER BY version DESC
    LIMIT 1
  `);

  const orgRow = orgResult.rows[0] as { name: string } | undefined;

  return {
    displayName: userRow.display_name,
    email: userRow.email,
    organizationName: orgRow?.name ?? "Organization",
  };
}
