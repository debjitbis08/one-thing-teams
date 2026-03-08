import { and, eq, sql } from "drizzle-orm";

import { db } from "../../../infrastructure/db/client";
import { snapshots } from "../../../infrastructure/db/schema";

const userAggregateType = "identity.user" as const;

export async function memberExistsForOrg(userId: string, organizationId: string): Promise<boolean> {
  const [row] = await db
    .select({ aggregateId: snapshots.aggregateId })
    .from(snapshots)
    .where(
      and(
        eq(snapshots.aggregateId, userId),
        eq(snapshots.aggregateType, userAggregateType),
        sql`${snapshots.state}->'memberships' @> ${JSON.stringify([{ organizationId }])}::jsonb`,
      ),
    )
    .limit(1);

  return !!row;
}
