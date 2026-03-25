import { and, eq } from "drizzle-orm";

import { db } from "../../../../infrastructure/db/client";
import { events } from "../../../../infrastructure/db/schema";

const productAggregateType = "pm.product" as const;

type ProductCreatedData = {
  productId: string;
  organizationId: string;
  name: string;
  shortCode: string;
  description: string | null;
  createdBy: string;
  occurredAt: string;
};

export type ProductReadModel = {
  productId: string;
  name: string;
  shortCode: string;
  description: string | null;
  createdBy: string;
  createdAt: string;
};

export async function listProductsForOrg(organizationId: string): Promise<ProductReadModel[]> {
  const rows = await db
    .select({ data: events.data })
    .from(events)
    .where(
      and(
        eq(events.orgId, organizationId),
        eq(events.aggregateType, productAggregateType),
        eq(events.type, "pm.product.created"),
      ),
    )
    .orderBy(events.createdAt);

  return rows.map(row => {
    const data = row.data as unknown as ProductCreatedData;
    return {
      productId: data.productId,
      name: data.name,
      shortCode: data.shortCode,
      description: data.description,
      createdBy: data.createdBy,
      createdAt: data.occurredAt,
    };
  });
}
