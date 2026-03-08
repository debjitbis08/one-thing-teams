import { eventRepository } from "../../../infrastructure/db/EventRepository";

const aggregateType = "pm.task" as const;

export type TaskAggregateData = {
  version: number;
  kind: string;
  events: Array<{
    version: number;
    type_: string;
    data: unknown;
  }>;
};

export async function loadTaskAggregate(taskId: string): Promise<TaskAggregateData | undefined> {
  const events = await eventRepository.loadStream({
    aggregateId: taskId,
  });

  const relevantEvents = events
    .filter(event => event.aggregateType === aggregateType)
    .map(event => ({
      version: event.version,
      type_: event.type,
      data: event.data,
    }));

  if (relevantEvents.length === 0) {
    return undefined;
  }

  const createdEvent = relevantEvents.find(e => e.type_ === "pm.task.created");
  const kind = (createdEvent?.data as Record<string, unknown>)?.kind as string ?? "unknown";

  const highestVersion = relevantEvents.at(-1)?.version ?? 0;

  return {
    version: highestVersion,
    kind,
    events: relevantEvents,
  };
}
