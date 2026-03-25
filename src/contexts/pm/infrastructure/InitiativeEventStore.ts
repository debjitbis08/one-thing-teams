import { v7 as uuidv7 } from "uuid";

import { eventRepository } from "../../../infrastructure/db/EventRepository";

const aggregateType = "pm.initiative" as const;
const createdEventType = `${aggregateType}.created` as const;
const scoredEventType = `${aggregateType}.scored` as const;
const progressStatusUpdatedEventType = `${aggregateType}.progress_status_updated` as const;
const lifecycleStatusUpdatedEventType = `${aggregateType}.lifecycle_status_updated` as const;

type CreatedEventInput = {
  initiativeId: string;
  productId: string;
  organizationId: string;
  slug: string;
  title: string;
  description: string | undefined;
  timeBudget: number;
  chatRoomLink: string | undefined;
  createdBy: string;
  occurredAt: number;
};

type ScoreNote = {
  value: number;
  note: string | undefined;
};

const serializeScoreNote = (sn: ScoreNote | undefined) =>
  sn ? { value: sn.value, note: sn.note ?? null } : null;

type ScoredEventInput = {
  initiativeId: string;
  organizationId: string;
  scoreType: string;
  userValue: ScoreNote | undefined;
  timeCriticality: ScoreNote | undefined;
  riskReduction: ScoreNote | undefined;
  effort: ScoreNote | undefined;
  isCore: boolean | undefined;
  contributionCount: number | undefined;
  scoredBy: string;
  sessionId: string;
  version: number;
  expectedVersion: number;
  occurredAt: Date;
};

export async function appendInitiativeScoredEvent(input: ScoredEventInput): Promise<void> {
  await eventRepository.append({
    events: [
      {
        id: uuidv7(),
        orgId: input.organizationId,
        aggregateId: input.initiativeId,
        aggregateType,
        version: input.version,
        type: scoredEventType,
        data: {
          initiativeId: input.initiativeId,
          organizationId: input.organizationId,
          scoreType: input.scoreType,
          userValue: serializeScoreNote(input.userValue),
          timeCriticality: serializeScoreNote(input.timeCriticality),
          riskReduction: serializeScoreNote(input.riskReduction),
          effort: serializeScoreNote(input.effort),
          isCore: input.isCore ?? null,
          contributionCount: input.contributionCount ?? null,
          scoredBy: input.scoredBy,
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
          slug: input.slug,
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

type ProgressStatusUpdatedEventInput = {
  initiativeId: string;
  organizationId: string;
  progressStatus: string;
  updatedBy: string;
  sessionId: string;
  version: number;
  expectedVersion: number;
  occurredAt: Date;
};

export async function appendProgressStatusUpdatedEvent(input: ProgressStatusUpdatedEventInput): Promise<void> {
  await eventRepository.append({
    events: [
      {
        id: uuidv7(),
        orgId: input.organizationId,
        aggregateId: input.initiativeId,
        aggregateType,
        version: input.version,
        type: progressStatusUpdatedEventType,
        data: {
          initiativeId: input.initiativeId,
          progressStatus: input.progressStatus,
          updatedBy: input.updatedBy,
          occurredAt: input.occurredAt.toISOString(),
        },
        meta: { sessionId: input.sessionId },
        createdAt: input.occurredAt,
      },
    ],
    expectedVersion: input.expectedVersion,
  });
}

type EvidenceItem = {
  kind: string;
  url?: string;
  description?: string;
  signedOffBy?: string;
  reason?: string;
};

type LifecycleStatusUpdatedEventInput = {
  initiativeId: string;
  organizationId: string;
  lifecycleStatus: string;
  evidence: EvidenceItem[];
  outcomeNotes: string | undefined;
  updatedBy: string;
  sessionId: string;
  version: number;
  expectedVersion: number;
  occurredAt: Date;
};

export async function appendLifecycleStatusUpdatedEvent(input: LifecycleStatusUpdatedEventInput): Promise<void> {
  await eventRepository.append({
    events: [
      {
        id: uuidv7(),
        orgId: input.organizationId,
        aggregateId: input.initiativeId,
        aggregateType,
        version: input.version,
        type: lifecycleStatusUpdatedEventType,
        data: {
          initiativeId: input.initiativeId,
          lifecycleStatus: input.lifecycleStatus,
          evidence: input.evidence,
          outcomeNotes: input.outcomeNotes ?? null,
          updatedBy: input.updatedBy,
          occurredAt: input.occurredAt.toISOString(),
        },
        meta: { sessionId: input.sessionId },
        createdAt: input.occurredAt,
      },
    ],
    expectedVersion: input.expectedVersion,
  });
}
