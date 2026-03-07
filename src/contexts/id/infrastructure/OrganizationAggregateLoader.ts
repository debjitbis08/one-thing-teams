import { and, eq, inArray, desc } from "drizzle-orm";

import type { RenameOrganization_aggregateData as AggregateData } from "../application/RenameOrganization.gen";
import type { orgDetails as OrgDetails } from "../application/RegisteredUserSnapshot.gen";
import { eventRepository } from "../../../infrastructure/db/EventRepository";
import { db } from "../../../infrastructure/db/client";
import { events } from "../../../infrastructure/db/schema";

const aggregateType = "identity.organization" as const;
const createdType = `${aggregateType}.created` as const;
const renamedType = `${aggregateType}.renamed` as const;

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

type OrgEventData = {
  organizationId?: string;
  name?: string;
  shortCode?: string;
  ownerId?: string;
};

export async function loadOrgDetailsByIds(orgIds: string[]): Promise<OrgDetails[]> {
  if (orgIds.length === 0) return [];

  const uniqueIds = [...new Set(orgIds)];

  // Load all org events for the requested IDs
  const rows = await db
    .select({ aggregateId: events.aggregateId, type: events.type, data: events.data })
    .from(events)
    .where(
      and(
        inArray(events.aggregateId, uniqueIds),
        eq(events.aggregateType, aggregateType),
      ),
    )
    .orderBy(events.aggregateId, events.version);

  // Fold events per org to derive current state
  const orgMap = new Map<string, OrgDetails>();

  for (const row of rows) {
    const data = row.data as OrgEventData;
    const existing = orgMap.get(row.aggregateId);

    if (row.type === createdType) {
      orgMap.set(row.aggregateId, {
        organizationId: row.aggregateId,
        name: data.name ?? "",
        shortCode: data.shortCode ?? "",
        ownerId: data.ownerId ?? "",
      });
    } else if (row.type === renamedType && existing) {
      existing.name = data.name ?? existing.name;
      existing.shortCode = data.shortCode ?? existing.shortCode;
    }
  }

  return Array.from(orgMap.values());
}
