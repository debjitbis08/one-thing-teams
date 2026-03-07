import { and, desc, eq, inArray, sql } from "drizzle-orm";

import { eventRepository } from "../../../infrastructure/db/EventRepository";
import { db } from "../../../infrastructure/db/client";
import { events } from "../../../infrastructure/db/schema";

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
  const loaded = await eventRepository.loadStream({
    aggregateId: invitationId,
  });

  const relevantEvents = loaded
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
  const [row] = await db
    .select({ aggregateId: events.aggregateId })
    .from(events)
    .where(
      and(
        eq(events.aggregateType, aggregateType),
        eq(events.type, "identity.invitation.created"),
        sql`${events.data}->>'tokenHash' = ${tokenHash}`,
      ),
    )
    .limit(1);

  return row?.aggregateId;
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

  const candidates = await db
    .select({
      aggregateId: events.aggregateId,
      data: events.data,
      createdAt: events.createdAt,
    })
    .from(events)
    .where(
      and(
        eq(events.aggregateType, aggregateType),
        eq(events.type, "identity.invitation.created"),
        eq(events.orgId, organizationId),
      ),
    )
    .orderBy(desc(events.createdAt));

  const pending: PendingInvitation[] = [];

  for (const candidate of candidates) {
    const data = candidate.data as { email: string; role: string; expiresAt: number };
    if (data.expiresAt < now) continue;

    // Check if there's an accepted or revoked event for this aggregate
    const [terminal] = await db
      .select({ type: events.type })
      .from(events)
      .where(
        and(
          eq(events.aggregateId, candidate.aggregateId),
          eq(events.aggregateType, aggregateType),
          inArray(events.type, ["identity.invitation.accepted", "identity.invitation.revoked"]),
        ),
      )
      .limit(1);

    if (!terminal) {
      pending.push({
        invitationId: candidate.aggregateId,
        email: data.email,
        role: data.role,
        createdAt: candidate.createdAt.toISOString(),
        expiresAt: data.expiresAt,
      });
    }
  }

  return pending;
}
