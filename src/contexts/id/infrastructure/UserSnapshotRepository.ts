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

  // First find the aggregate_id matching the identifier
  const idResult = await db.execute(sql<{
    aggregate_id: string;
  }>`
    SELECT DISTINCT aggregate_id
    FROM "snapshots"
    WHERE aggregate_type = ${aggregateType}
      AND (
        state->'user'->>'username' = ${trimmed}
        OR state->'user'->>'email' = ${emailCandidate}
      )
    LIMIT 1
  `);

  const idRow = idResult.rows[0] as { aggregate_id: string } | undefined;
  if (!idRow) {
    return undefined;
  }

  // Then get the latest snapshot for that specific aggregate
  const result = await db.execute(sql<{
    state: RegisteredUserSnapshot;
  }>`
    SELECT state
    FROM "snapshots"
    WHERE aggregate_id = ${idRow.aggregate_id}
      AND aggregate_type = ${aggregateType}
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

export const updateOrganizationInUserSnapshots = async (
  organizationId: string,
  newName: string,
  newShortCode: string,
): Promise<void> => {
  // Find all user snapshots that reference this organization
  // We check defaultOrganization, preferredOrganization, and within memberships array
  const result = await db.execute(sql<{
    aggregate_id: string;
    version: number;
    state: RegisteredUserSnapshot;
  }>`
    SELECT aggregate_id, version, state
    FROM "snapshots"
    WHERE aggregate_type = ${aggregateType}
      AND (
        state->'defaultOrganization'->>'organizationId' = ${organizationId}
        OR state->'preferredOrganization'->>'organizationId' = ${organizationId}
        OR EXISTS (
          SELECT 1 FROM jsonb_array_elements(state->'memberships') AS membership
          WHERE membership->'organization'->>'organizationId' = ${organizationId}
        )
      )
  `);

  // Update each snapshot with the new organization name
  for (const row of result.rows as Array<{ aggregate_id: string; version: number; state: RegisteredUserSnapshot }>) {
    const snapshot = row.state;
    let needsUpdate = false;

    // Check if this snapshot references the organization
    if (
      snapshot.defaultOrganization.organizationId === organizationId ||
      snapshot.preferredOrganization.organizationId === organizationId ||
      snapshot.memberships.some(m => m.organization.organizationId === organizationId)
    ) {
      needsUpdate = true;
    }

    if (needsUpdate) {
      const now = Date.now();

      // Create updated snapshot with new organization data
      const updatedSnapshot: RegisteredUserSnapshot = {
        ...snapshot,
        defaultOrganization:
          snapshot.defaultOrganization.organizationId === organizationId
            ? { ...snapshot.defaultOrganization, name: newName, shortCode: newShortCode }
            : snapshot.defaultOrganization,
        preferredOrganization:
          snapshot.preferredOrganization.organizationId === organizationId
            ? { ...snapshot.preferredOrganization, name: newName, shortCode: newShortCode }
            : snapshot.preferredOrganization,
        memberships: snapshot.memberships.map(membership =>
          membership.organization.organizationId === organizationId
            ? {
                ...membership,
                organization: { ...membership.organization, name: newName, shortCode: newShortCode },
              }
            : membership
        ),
        updatedAt: now,
      };

      // Persist the updated snapshot with a new version
      await eventRepository.persistSnapshot({
        aggregateId: row.aggregate_id,
        aggregateType,
        version: row.version + 1,
        state: JSON.parse(JSON.stringify(updatedSnapshot)),
        createdAt: new Date(now),
      });
    }
  }
};
