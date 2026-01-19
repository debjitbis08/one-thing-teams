import type { RenameOrganization_aggregateData as AggregateData } from "../application/RenameOrganization.gen";
import { eventRepository } from "../../../infrastructure/db/EventRepository";

const aggregateType = "identity.organization" as const;

export async function loadOrganizationAggregate(organizationId: string): Promise<AggregateData | undefined> {
  const snapshotRow = await eventRepository.loadLatestSnapshot(organizationId);
  const snapshot = snapshotRow && snapshotRow.aggregateType === aggregateType
    ? {
        version: snapshotRow.version,
        state: snapshotRow.state as AggregateData["snapshot"] extends { state: infer S } ? S : never,
      }
    : undefined;

  const fromVersion = snapshot ? snapshot.version + 1 : undefined;

  const events = await eventRepository.loadStream({
    aggregateId: organizationId,
    fromVersion,
  });

  const relevantEvents = events
    .filter(event => event.aggregateType === aggregateType)
    .map(event => ({
      version: event.version,
      type_: event.type,
      data: event.data as AggregateData["events"][number]["data"],
    }));

  if (!snapshot && relevantEvents.length === 0) {
    return undefined;
  }

  const highestEventVersion = relevantEvents.at(-1)?.version ?? 0;
  const aggregateVersion = Math.max(highestEventVersion, snapshot?.version ?? 0);

  return {
    version: aggregateVersion,
    snapshot,
    events: relevantEvents,
  };
}
