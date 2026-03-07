import { and, desc, eq, sql } from "drizzle-orm";
import { v7 as uuidv7 } from "uuid";

import type {
  dependencies as Dependencies,
  acceptedEvent as AcceptedEvent,
  membershipAddition as MembershipAddition,
} from "../application/AcceptInvitation.gen";
import { appendInvitationAcceptedEvent } from "./InvitationEventStore";
import { loadInvitationAggregate, findInvitationIdByTokenHash } from "./InvitationAggregateLoader";
import { hashInvitationToken } from "./InvitationTokenService";
import { db } from "../../../infrastructure/db/client";
import { events as eventsTable, snapshots } from "../../../infrastructure/db/schema";
import { eventRepository } from "../../../infrastructure/db/EventRepository";
import type { snapshot as RegisteredUserSnapshot } from "../application/RegisteredUserSnapshot.gen";

const userAggregateType = "identity.user" as const;

const getUserEmail = async (userId: string): Promise<string | undefined> => {
  const [row] = await db
    .select({ email: sql<string>`${snapshots.state}->'user'->>'email'` })
    .from(snapshots)
    .where(
      and(
        eq(snapshots.aggregateType, userAggregateType),
        eq(snapshots.aggregateId, userId),
      ),
    )
    .orderBy(desc(snapshots.version))
    .limit(1);

  return row?.email ?? undefined;
};

const addMembershipToUser = async (membership: MembershipAddition): Promise<void> => {
  const [row] = await db
    .select({
      aggregateId: snapshots.aggregateId,
      orgId: snapshots.orgId,
      version: snapshots.version,
      state: snapshots.state,
    })
    .from(snapshots)
    .where(
      and(
        eq(snapshots.aggregateType, userAggregateType),
        eq(snapshots.aggregateId, membership.userId),
      ),
    )
    .orderBy(desc(snapshots.version))
    .limit(1);

  if (!row) return;

  const snapshot = row.state as RegisteredUserSnapshot;

  // Check if membership already exists
  const alreadyMember = snapshot.memberships.some(
    m => m.organizationId === membership.organizationId,
  );
  if (alreadyMember) return;

  const now = new Date();
  const newVersion = row.version + 1;

  // Load current event version for the user aggregate
  const [latestEvent] = await db
    .select({ version: eventsTable.version })
    .from(eventsTable)
    .where(eq(eventsTable.aggregateId, membership.userId))
    .orderBy(desc(eventsTable.version))
    .limit(1);
  const currentEventVersion = latestEvent?.version ?? 0;

  // Append membership_added event to user aggregate
  await eventRepository.append({
    events: [
      {
        id: uuidv7(),
        orgId: row.orgId,
        aggregateId: membership.userId,
        aggregateType: userAggregateType,
        version: currentEventVersion + 1,
        type: "identity.user.membership_added",
        data: {
          organizationId: membership.organizationId,
          organizationName: membership.organizationName,
          role: membership.role,
        },
        meta: {},
        createdAt: now,
      },
    ],
    expectedVersion: currentEventVersion,
  });

  // Update snapshot to reflect the new membership
  const updatedSnapshot: RegisteredUserSnapshot = {
    ...snapshot,
    memberships: [
      ...snapshot.memberships,
      {
        organizationId: membership.organizationId,
        role: membership.role,
      },
    ],
    updatedAt: now.getTime(),
  };

  await eventRepository.persistSnapshot({
    aggregateId: row.aggregateId,
    aggregateType: userAggregateType,
    orgId: row.orgId,
    version: newVersion,
    state: JSON.parse(JSON.stringify(updatedSnapshot)),
    createdAt: now,
  });
};

export const acceptInvitationDependencies: Dependencies = {
  now: () => Date.now(),
  hashToken: (token: string) => hashInvitationToken(token),
  findInvitationIdByTokenHash: async (tokenHash: string) => {
    const id = await findInvitationIdByTokenHash(tokenHash);
    return id ?? undefined;
  },
  loadAggregate: async (invitationId: string) => {
    const aggregate = await loadInvitationAggregate(invitationId);
    return aggregate ?? undefined;
  },
  appendEvent: async (event: AcceptedEvent) => {
    await appendInvitationAcceptedEvent(event);
  },
  addMembership: async (membership: MembershipAddition) => {
    await addMembershipToUser(membership);
  },
  getUserEmail: async (userId: string) => {
    const email = await getUserEmail(userId);
    return email ?? undefined;
  },
};
