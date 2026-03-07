import { v7 as uuidv7 } from "uuid";

import { eventRepository } from "../../../infrastructure/db/EventRepository";

const aggregateType = "pm.product" as const;
const createdEventType = `${aggregateType}.created` as const;

type CreatedEventInput = {
  productId: string;
  organizationId: string;
  name: string;
  shortCode: string;
  description: string | undefined;
  createdBy: string;
  occurredAt: number;
};

export async function appendProductCreatedEvent(input: CreatedEventInput): Promise<void> {
  const occurredAt = new Date(input.occurredAt);

  await eventRepository.append({
    events: [
      {
        id: uuidv7(),
        orgId: input.organizationId,
        aggregateId: input.productId,
        aggregateType,
        version: 1,
        type: createdEventType,
        data: {
          productId: input.productId,
          organizationId: input.organizationId,
          name: input.name,
          shortCode: input.shortCode,
          description: input.description ?? null,
          createdBy: input.createdBy,
          occurredAt: occurredAt.toISOString(),
        },
        meta: {},
        createdAt: occurredAt,
      },
    ],
    expectedVersion: 0,
  });
}
