import { v7 as uuidv7 } from "uuid";

import { eventRepository } from "../../../infrastructure/db/EventRepository";

const aggregateType = "pm.initiative" as const;
const createdEventType = `${aggregateType}.created` as const;

type CreatedEventInput = {
  initiativeId: string;
  productId: string;
  organizationId: string;
  title: string;
  description: string | undefined;
  timeBudget: number;
  chatRoomLink: string | undefined;
  createdBy: string;
  occurredAt: number;
};

export async function appendInitiativeCreatedEvent(input: CreatedEventInput): Promise<void> {
  const occurredAt = new Date(input.occurredAt);

  await eventRepository.append({
    events: [
      {
        id: uuidv7(),
        orgId: input.organizationId,
        aggregateId: input.initiativeId,
        aggregateType,
        version: 1,
        type: createdEventType,
        data: {
          initiativeId: input.initiativeId,
          productId: input.productId,
          organizationId: input.organizationId,
          title: input.title,
          description: input.description ?? null,
          timeBudget: input.timeBudget,
          chatRoomLink: input.chatRoomLink ?? null,
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
