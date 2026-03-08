import type { aggregateData as AggregateData } from "../application/ScoreInitiative.gen";
import { eventRepository } from "../../../infrastructure/db/EventRepository";

const aggregateType = "pm.initiative" as const;

export async function loadInitiativeAggregate(initiativeId: string): Promise<AggregateData | undefined> {
  const events = await eventRepository.loadStream({
    aggregateId: initiativeId,
  });

  const relevantEvents = events
    .filter(event => event.aggregateType === aggregateType)
    .map(event => ({
      version: event.version,
      type_: event.type,
      data: event.data as AggregateData["events"][number]["data"],
    }));

  if (relevantEvents.length === 0) {
    return undefined;
  }

  const highestVersion = relevantEvents.at(-1)?.version ?? 0;

  return {
    version: highestVersion,
    events: relevantEvents,
  };
}
