import { and, eq } from "drizzle-orm";

import { db } from "../../../infrastructure/db/client";
import { events } from "../../../infrastructure/db/schema";

const productAggregateType = "pm.product" as const;
const initiativeAggregateType = "pm.initiative" as const;
const emergencyAggregateType = "pm.emergency" as const;

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

export async function initiativeExistsForOrg(initiativeId: string, organizationId: string): Promise<boolean> {
  const [row] = await db
    .select({ aggregateId: events.aggregateId })
    .from(events)
    .where(
      and(
        eq(events.aggregateId, initiativeId),
        eq(events.aggregateType, initiativeAggregateType),
        eq(events.type, "pm.initiative.created"),
        eq(events.orgId, organizationId),
      ),
    )
    .limit(1);

  return !!row;
}

export async function emergencyExistsForOrg(emergencyId: string, organizationId: string): Promise<boolean> {
  const [row] = await db
    .select({ aggregateId: events.aggregateId })
    .from(events)
    .where(
      and(
        eq(events.aggregateId, emergencyId),
        eq(events.aggregateType, emergencyAggregateType),
        eq(events.type, "pm.emergency.created"),
        eq(events.orgId, organizationId),
      ),
    )
    .limit(1);

  return !!row;
}
