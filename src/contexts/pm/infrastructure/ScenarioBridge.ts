import type {
  dependencies as AddDependencies,
  addedEvent as AddedEvent,
} from "../application/AddScenario.gen";
import type {
  dependencies as RemoveDependencies,
  removedEvent as RemovedEvent,
} from "../application/RemoveScenario.gen";
import { appendScenarioAddedEvent, appendScenarioRemovedEvent } from "./TaskEventStore";
import { loadTaskAggregate } from "./TaskAggregateLoader";

const loadTask = async (taskId: string) => {
  const aggregate = await loadTaskAggregate(taskId);
  if (!aggregate) return undefined;
  return { version: aggregate.version, kind: aggregate.kind };
};

export const addScenarioBridgeFactory = (): AddDependencies => ({
  now: () => Date.now(),
  loadTask,
  appendEvent: async (event: AddedEvent) => {
    await appendScenarioAddedEvent({
      taskId: event.taskId,
      organizationId: event.organizationId,
      scenarioId: event.scenarioId,
      title: event.title,
      addedBy: event.addedBy,
      sessionId: event.sessionId,
      version: event.version,
      expectedVersion: event.expectedVersion,
      occurredAt: new Date(event.occurredAt),
    });
  },
});

export const removeScenarioBridgeFactory = (): RemoveDependencies => ({
  now: () => Date.now(),
  loadTask,
  appendEvent: async (event: RemovedEvent) => {
    await appendScenarioRemovedEvent({
      taskId: event.taskId,
      organizationId: event.organizationId,
      scenarioId: event.scenarioId,
      removedBy: event.removedBy,
      sessionId: event.sessionId,
      version: event.version,
      expectedVersion: event.expectedVersion,
      occurredAt: new Date(event.occurredAt),
    });
  },
});
