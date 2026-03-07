import { v7 as uuidv7 } from "uuid";

import { eventRepository } from "../../../infrastructure/db/EventRepository";

const aggregateType = "identity.invitation" as const;
const createdEventType = `${aggregateType}.created` as const;
const acceptedEventType = `${aggregateType}.accepted` as const;
const revokedEventType = `${aggregateType}.revoked` as const;

type CreatedEventInput = {
  invitationId: string;
  organizationId: string;
  organizationName: string;
  email: string;
  role: string;
  tokenHash: string;
  createdBy: string;
  expiresAt: number;
  occurredAt: number;
};

type AcceptedEventInput = {
  invitationId: string;
  organizationId: string;
  acceptedBy: string;
  expectedVersion: number;
  version: number;
  occurredAt: number;
};

type RevokedEventInput = {
  invitationId: string;
  organizationId: string;
  revokedBy: string;
  expectedVersion: number;
  version: number;
  occurredAt: number;
};

export async function appendInvitationCreatedEvent(input: CreatedEventInput): Promise<void> {
  const occurredAt = new Date(input.occurredAt);

  await eventRepository.append({
    events: [
      {
        id: uuidv7(),
        orgId: input.organizationId,
        aggregateId: input.invitationId,
        aggregateType,
        version: 1,
        type: createdEventType,
        data: {
          invitationId: input.invitationId,
          organizationId: input.organizationId,
          organizationName: input.organizationName,
          email: input.email,
          role: input.role,
          tokenHash: input.tokenHash,
          createdBy: input.createdBy,
          expiresAt: input.expiresAt,
          occurredAt: occurredAt.toISOString(),
        },
        meta: {},
        createdAt: occurredAt,
      },
    ],
    expectedVersion: 0,
  });
}

export async function appendInvitationAcceptedEvent(input: AcceptedEventInput): Promise<void> {
  const occurredAt = new Date(input.occurredAt);

  await eventRepository.append({
    events: [
      {
        id: uuidv7(),
        orgId: input.organizationId,
        aggregateId: input.invitationId,
        aggregateType,
        version: input.version,
        type: acceptedEventType,
        data: {
          invitationId: input.invitationId,
          acceptedBy: input.acceptedBy,
          occurredAt: occurredAt.toISOString(),
        },
        meta: {},
        createdAt: occurredAt,
      },
    ],
    expectedVersion: input.expectedVersion,
  });
}

export async function appendInvitationRevokedEvent(input: RevokedEventInput): Promise<void> {
  const occurredAt = new Date(input.occurredAt);

  await eventRepository.append({
    events: [
      {
        id: uuidv7(),
        orgId: input.organizationId,
        aggregateId: input.invitationId,
        aggregateType,
        version: input.version,
        type: revokedEventType,
        data: {
          invitationId: input.invitationId,
          revokedBy: input.revokedBy,
          occurredAt: occurredAt.toISOString(),
        },
        meta: {},
        createdAt: occurredAt,
      },
    ],
    expectedVersion: input.expectedVersion,
  });
}
