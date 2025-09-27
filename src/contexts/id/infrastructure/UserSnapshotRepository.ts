import { sql } from "drizzle-orm";

import type { registrationEvent } from "../application/RegisterWithPassword.gen";
import { snapshotOfRegisteredUser, registeredUserOfSnapshot } from "../application/RegisteredUserSnapshot.gen";
import type { snapshot as RegisteredUserSnapshot } from "../application/RegisteredUserSnapshot.gen";
import { eventRepository } from "../../../infrastructure/db/EventRepository";
import { db } from "../../../infrastructure/db/client";

const aggregateType = "identity.user" as const;

export const storeRegisteredUserSnapshot = async (
  event: registrationEvent,
  registeredUser: Parameters<typeof snapshotOfRegisteredUser>[0],
) => {
  const snapshot = snapshotOfRegisteredUser(registeredUser);
  const state = JSON.parse(JSON.stringify(snapshot)) as RegisteredUserSnapshot;

  await eventRepository.persistSnapshot({
    aggregateId: snapshot.user.userId,
    aggregateType,
    version: event.version,
    state,
    createdAt: new Date(snapshot.updatedAt),
  });
};

export const fetchRegisteredUserByIdentifier = async (identifier: string) => {
  const trimmed = identifier.trim();
  const emailCandidate = trimmed.toLowerCase();

  const result = await db.execute(sql<{
    state: RegisteredUserSnapshot;
  }>`
    SELECT state
    FROM "snapshots"
    WHERE aggregate_type = ${aggregateType}
      AND (
        state->'user'->>'username' = ${trimmed}
        OR state->'user'->>'email' = ${emailCandidate}
      )
    ORDER BY version DESC
    LIMIT 1
  `);

  const row = result.rows[0] as { state: RegisteredUserSnapshot } | undefined;
  if (!row) {
    return undefined;
  }

  const registeredUser = registeredUserOfSnapshot(row.state);
  return registeredUser ?? undefined;
};
