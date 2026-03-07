import { sql } from "drizzle-orm";

import { eventRepository } from "../../../infrastructure/db/EventRepository";
import { db } from "../../../infrastructure/db/client";

const aggregateType = "identity.invitation" as const;

type AggregateData = {
  version: number;
  events: Array<{
    version: number;
    type_: string;
    data: unknown;
  }>;
};

export async function loadInvitationAggregate(invitationId: string): Promise<AggregateData | undefined> {
  const events = await eventRepository.loadStream({
    aggregateId: invitationId,
  });

  const relevantEvents = events
    .filter(event => event.aggregateType === aggregateType)
    .map(event => ({
      version: event.version,
      type_: event.type,
      data: event.data as unknown,
    }));

  if (relevantEvents.length === 0) {
    return undefined;
  }

  const highestEventVersion = relevantEvents.at(-1)?.version ?? 0;

  return {
    version: highestEventVersion,
    events: relevantEvents,
  };
}

export async function findInvitationIdByTokenHash(tokenHash: string): Promise<string | undefined> {
  const result = await db.execute(sql`
    SELECT aggregate_id
    FROM "events"
    WHERE aggregate_type = ${aggregateType}
      AND type = 'identity.invitation.created'
      AND data->>'tokenHash' = ${tokenHash}
    LIMIT 1
  `);

  const row = result.rows[0] as { aggregate_id: string } | undefined;
  return row?.aggregate_id;
}

type PendingInvitation = {
  invitationId: string;
  email: string;
  role: string;
  createdAt: string;
  expiresAt: number;
};

export async function listPendingInvitations(organizationId: string): Promise<PendingInvitation[]> {
  const now = Date.now();

  // Load all created events for this org, then filter by checking full aggregate state
  const result = await db.execute(sql`
    SELECT aggregate_id, data, created_at
    FROM "events"
    WHERE aggregate_type = ${aggregateType}
      AND type = 'identity.invitation.created'
      AND org_id = ${organizationId}
    ORDER BY created_at DESC
  `);

  const candidates = result.rows as Array<{
    aggregate_id: string;
    data: { email: string; role: string; expiresAt: number };
    created_at: string | Date;
  }>;

  // Filter out expired, accepted, and revoked invitations
  const pending: PendingInvitation[] = [];

  for (const candidate of candidates) {
    if (candidate.data.expiresAt < now) continue;

    // Check if there's an accepted or revoked event for this aggregate
    const statusResult = await db.execute(sql`
      SELECT type FROM "events"
      WHERE aggregate_id = ${candidate.aggregate_id}
        AND aggregate_type = ${aggregateType}
        AND type IN ('identity.invitation.accepted', 'identity.invitation.revoked')
      LIMIT 1
    `);

    if (statusResult.rows.length === 0) {
      const createdAt = candidate.created_at instanceof Date
        ? candidate.created_at.toISOString()
        : String(candidate.created_at);

      pending.push({
        invitationId: candidate.aggregate_id,
        email: candidate.data.email,
        role: candidate.data.role,
        createdAt,
        expiresAt: candidate.data.expiresAt,
      });
    }
  }

  return pending;
}
