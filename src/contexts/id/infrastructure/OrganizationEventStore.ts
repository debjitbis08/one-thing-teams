import { v7 as uuidv7 } from "uuid";

import { eventRepository } from "../../../infrastructure/db/EventRepository";

const aggregateType = "identity.organization" as const;
const createdEventType = `${aggregateType}.created` as const;
const renamedEventType = `${aggregateType}.renamed` as const;

type BaseEventInput = {
  organizationId: string;
  occurredAt: Date;
};

type CreatedEventInput = BaseEventInput & {
  name: string;
  shortCode: string;
  ownerId: string;
  createdBy: string;
};

type RenamedEventInput = BaseEventInput & {
  name: string;
  shortCode: string;
  renamedBy: string;
  sessionId: string;
  version: number;
  expectedVersion: number;
};

export async function appendOrganizationCreatedEvent(input: CreatedEventInput): Promise<void> {
  await eventRepository.append({
    events: [
      {
        id: uuidv7(),
        orgId: input.organizationId,
        aggregateId: input.organizationId,
        aggregateType,
        version: 1,
        type: createdEventType,
        data: {
          organizationId: input.organizationId,
          name: input.name,
          shortCode: input.shortCode,
          ownerId: input.ownerId,
          createdBy: input.createdBy,
          occurredAt: input.occurredAt.toISOString(),
        },
        meta: {},
        createdAt: input.occurredAt,
      },
    ],
    expectedVersion: 0,
  });
}

export async function appendOrganizationRenamedEvent(input: RenamedEventInput): Promise<void> {
  await eventRepository.append({
    events: [
      {
        id: uuidv7(),
        orgId: input.organizationId,
        aggregateId: input.organizationId,
        aggregateType,
        version: input.version,
        type: renamedEventType,
        data: {
          organizationId: input.organizationId,
          name: input.name,
          shortCode: input.shortCode,
          renamedBy: input.renamedBy,
          occurredAt: input.occurredAt.toISOString(),
        },
        meta: {
          sessionId: input.sessionId,
        },
        createdAt: input.occurredAt,
      },
    ],
    expectedVersion: input.expectedVersion,
  });
}
