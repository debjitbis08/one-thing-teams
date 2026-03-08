import { v7 as uuidv7 } from "uuid";

import { eventRepository } from "../../../infrastructure/db/EventRepository";

const aggregateType = "pm.task" as const;
const createdEventType = `${aggregateType}.created` as const;
const scenarioAddedEventType = `${aggregateType}.scenario_added` as const;
const scenarioRemovedEventType = `${aggregateType}.scenario_removed` as const;

type ScenarioInput = {
  title: string;
  acceptanceCriteria: string[];
};

type CreatedEventInput = {
  taskId: string;
  organizationId: string;
  title: string;
  description: string | undefined;
  kind: string;
  initiativeId: string | undefined;
  productId: string | undefined;
  emergencyId: string | undefined;
  scenarios: ScenarioInput[] | undefined;
  createdBy: string;
  occurredAt: number;
};

type ScenarioAddedEventInput = {
  taskId: string;
  organizationId: string;
  scenarioId: string;
  title: string;
  addedBy: string;
  sessionId: string;
  version: number;
  expectedVersion: number;
  occurredAt: Date;
};

type ScenarioRemovedEventInput = {
  taskId: string;
  organizationId: string;
  scenarioId: string;
  removedBy: string;
  sessionId: string;
  version: number;
  expectedVersion: number;
  occurredAt: Date;
};

export async function appendScenarioAddedEvent(input: ScenarioAddedEventInput): Promise<void> {
  await eventRepository.append({
    events: [
      {
        id: uuidv7(),
        orgId: input.organizationId,
        aggregateId: input.taskId,
        aggregateType,
        version: input.version,
        type: scenarioAddedEventType,
        data: {
          taskId: input.taskId,
          scenarioId: input.scenarioId,
          title: input.title,
          addedBy: input.addedBy,
          occurredAt: input.occurredAt.toISOString(),
        },
        meta: { sessionId: input.sessionId },
        createdAt: input.occurredAt,
      },
    ],
    expectedVersion: input.expectedVersion,
  });
}

export async function appendScenarioRemovedEvent(input: ScenarioRemovedEventInput): Promise<void> {
  await eventRepository.append({
    events: [
      {
        id: uuidv7(),
        orgId: input.organizationId,
        aggregateId: input.taskId,
        aggregateType,
        version: input.version,
        type: scenarioRemovedEventType,
        data: {
          taskId: input.taskId,
          scenarioId: input.scenarioId,
          removedBy: input.removedBy,
          occurredAt: input.occurredAt.toISOString(),
        },
        meta: { sessionId: input.sessionId },
        createdAt: input.occurredAt,
      },
    ],
    expectedVersion: input.expectedVersion,
  });
}

export async function appendTaskCreatedEvent(input: CreatedEventInput): Promise<void> {
  const occurredAt = new Date(input.occurredAt);

  await eventRepository.append({
    events: [
      {
        id: uuidv7(),
        orgId: input.organizationId,
        aggregateId: input.taskId,
        aggregateType,
        version: 1,
        type: createdEventType,
        data: {
          taskId: input.taskId,
          organizationId: input.organizationId,
          title: input.title,
          description: input.description ?? null,
          kind: input.kind,
          initiativeId: input.initiativeId ?? null,
          productId: input.productId ?? null,
          emergencyId: input.emergencyId ?? null,
          scenarios: input.scenarios ?? null,
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
