import type {
  dependencies as ProgressDependencies,
  progressStatusUpdatedEvent as ProgressEvent,
} from "../application/UpdateProgressStatus.gen";
import type {
  dependencies as LifecycleDependencies,
  lifecycleStatusUpdatedEvent as LifecycleEvent,
} from "../application/UpdateLifecycleStatus.gen";
import {
  appendProgressStatusUpdatedEvent,
  appendLifecycleStatusUpdatedEvent,
} from "./InitiativeEventStore";
import { loadInitiativeAggregate } from "./InitiativeAggregateLoader";

const loadInitiative = async (initiativeId: string) => {
  const aggregate = await loadInitiativeAggregate(initiativeId);
  if (!aggregate) return undefined;

  const hasCreated = aggregate.events.some(e => e.type_ === "pm.initiative.created");
  return { version: aggregate.version, exists: hasCreated };
};

export const updateProgressStatusBridgeFactory = (): ProgressDependencies => ({
  now: () => Date.now(),
  loadInitiative,
  appendEvent: async (event: ProgressEvent) => {
    await appendProgressStatusUpdatedEvent({
      initiativeId: event.initiativeId,
      organizationId: event.organizationId,
      progressStatus: event.progressStatus,
      updatedBy: event.updatedBy,
      sessionId: event.sessionId,
      version: event.version,
      expectedVersion: event.expectedVersion,
      occurredAt: new Date(event.occurredAt),
    });
  },
});

export const updateLifecycleStatusBridgeFactory = (): LifecycleDependencies => ({
  now: () => Date.now(),
  loadInitiative,
  appendEvent: async (event: LifecycleEvent) => {
    await appendLifecycleStatusUpdatedEvent({
      initiativeId: event.initiativeId,
      organizationId: event.organizationId,
      lifecycleStatus: event.lifecycleStatus,
      doneEvidence: event.doneEvidence ?? undefined,
      outcomeNotes: event.outcomeNotes ?? undefined,
      updatedBy: event.updatedBy,
      sessionId: event.sessionId,
      version: event.version,
      expectedVersion: event.expectedVersion,
      occurredAt: new Date(event.occurredAt),
    });
  },
});
