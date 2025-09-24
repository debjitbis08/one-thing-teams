import { and, desc, eq, gte } from "drizzle-orm";

import type {
  AppendEventsOptions,
  EventRepository,
  LoadStreamOptions,
  NewEvent,
  NewSnapshot,
  StoredEvent,
  StoredSnapshot,
} from "../../contexts/foundation/application/EventRepository";
import { db } from "./client";
import { events as eventsTable, snapshots as snapshotsTable } from "./schema";

const mapEvent = (row: typeof eventsTable.$inferSelect): StoredEvent => ({
  id: row.id,
  orgId: row.orgId,
  aggregateId: row.aggregateId,
  aggregateType: row.aggregateType,
  version: row.version,
  type: row.type,
  data: row.data as StoredEvent["data"],
  meta: row.meta as StoredEvent["meta"],
  createdAt: row.createdAt,
});

const mapSnapshot = (row: typeof snapshotsTable.$inferSelect): StoredSnapshot => ({
  aggregateId: row.aggregateId,
  aggregateType: row.aggregateType,
  version: row.version,
  state: row.state as StoredSnapshot["state"],
  createdAt: row.createdAt,
});

const prepareEventValues = (event: NewEvent): typeof eventsTable.$inferInsert => ({
  id: event.id,
  orgId: event.orgId,
  aggregateId: event.aggregateId,
  aggregateType: event.aggregateType,
  version: event.version,
  type: event.type,
  data: event.data,
  meta: event.meta ?? {},
  createdAt: event.createdAt,
});

const prepareSnapshotValues = (snapshot: NewSnapshot): typeof snapshotsTable.$inferInsert => ({
  aggregateId: snapshot.aggregateId,
  aggregateType: snapshot.aggregateType,
  version: snapshot.version,
  state: snapshot.state,
  createdAt: snapshot.createdAt ?? new Date(),
});

export const eventRepository: EventRepository = {
  async append({ events, expectedVersion }: AppendEventsOptions) {
    if (events.length === 0) {
      return;
    }

    const aggregateId = events[0]?.aggregateId;

    await db.transaction(async tx => {
      if (expectedVersion !== undefined) {
        const [latest] = await tx
          .select({ version: eventsTable.version })
          .from(eventsTable)
          .where(eq(eventsTable.aggregateId, aggregateId))
          .orderBy(desc(eventsTable.version))
          .limit(1);

        const currentVersion = latest?.version ?? 0;
        if (currentVersion !== expectedVersion) {
          throw new Error(
            `Concurrency conflict for aggregate ${aggregateId}: expected version ${expectedVersion}, actual ${currentVersion}`,
          );
        }
      }

      await tx.insert(eventsTable).values(events.map(prepareEventValues));
    });
  },

  async loadStream({ aggregateId, fromVersion }: LoadStreamOptions): Promise<StoredEvent[]> {
    const rows = fromVersion !== undefined
      ? await db
          .select()
          .from(eventsTable)
          .where(
            and(
              eq(eventsTable.aggregateId, aggregateId),
              gte(eventsTable.version, fromVersion),
            ),
          )
          .orderBy(eventsTable.version)
      : await db
          .select()
          .from(eventsTable)
          .where(eq(eventsTable.aggregateId, aggregateId))
          .orderBy(eventsTable.version);

    return rows.map(mapEvent);
  },

  async loadLatestSnapshot(aggregateId: string): Promise<StoredSnapshot | null> {
    const [row] = await db
      .select()
      .from(snapshotsTable)
      .where(eq(snapshotsTable.aggregateId, aggregateId))
      .orderBy(desc(snapshotsTable.version))
      .limit(1);

    return row ? mapSnapshot(row) : null;
  },

  async persistSnapshot(snapshot: NewSnapshot): Promise<void> {
    await db
      .insert(snapshotsTable)
      .values(prepareSnapshotValues(snapshot))
      .onConflictDoUpdate({
        target: [snapshotsTable.aggregateId, snapshotsTable.version],
        set: {
          state: snapshot.state,
          createdAt: snapshot.createdAt ?? new Date(),
        },
      });
  },
};
