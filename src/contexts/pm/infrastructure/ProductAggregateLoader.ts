import { and, eq } from "drizzle-orm";

import { db } from "../../../infrastructure/db/client";
import { events } from "../../../infrastructure/db/schema";

const productAggregateType = "pm.product" as const;

export async function productExistsForOrg(productId: string, organizationId: string): Promise<boolean> {
  const [row] = await db
    .select({ aggregateId: events.aggregateId })
    .from(events)
    .where(
      and(
        eq(events.aggregateId, productId),
        eq(events.aggregateType, productAggregateType),
        eq(events.type, "pm.product.created"),
        eq(events.orgId, organizationId),
      ),
    )
    .limit(1);

  return !!row;
}
