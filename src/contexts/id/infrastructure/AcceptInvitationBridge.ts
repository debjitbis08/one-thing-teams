import { sql } from "drizzle-orm";

import type {
  dependencies as Dependencies,
  acceptedEvent as AcceptedEvent,
  membershipAddition as MembershipAddition,
} from "../application/AcceptInvitation.gen";
import { appendInvitationAcceptedEvent } from "./InvitationEventStore";
import { loadInvitationAggregate, findInvitationIdByTokenHash } from "./InvitationAggregateLoader";
import { hashInvitationToken } from "./InvitationTokenService";
import { db } from "../../../infrastructure/db/client";
import { eventRepository } from "../../../infrastructure/db/EventRepository";
import type { snapshot as RegisteredUserSnapshot } from "../application/RegisteredUserSnapshot.gen";

const getUserEmail = async (userId: string): Promise<string | undefined> => {
  const result = await db.execute(sql`
    SELECT state->'user'->>'email' as email
    FROM "snapshots"
    WHERE aggregate_type = 'identity.user'
      AND aggregate_id = ${userId}
    ORDER BY version DESC
    LIMIT 1
  `);

  const row = result.rows[0] as { email: string } | undefined;
  return row?.email;
};

const addMembershipToUser = async (membership: MembershipAddition): Promise<void> => {
  // Load the user's latest snapshot
  const result = await db.execute(sql`
    SELECT aggregate_id, version, state
    FROM "snapshots"
    WHERE aggregate_type = 'identity.user'
      AND aggregate_id = ${membership.userId}
    ORDER BY version DESC
    LIMIT 1
  `);

  const row = result.rows[0] as {
    aggregate_id: string;
    version: number;
    state: RegisteredUserSnapshot;
  } | undefined;

  if (!row) return;

  const snapshot = row.state;

  // Check if membership already exists
  const alreadyMember = snapshot.memberships.some(
    m => m.organization.organizationId === membership.organizationId,
  );
  if (alreadyMember) return;

  const updatedSnapshot: RegisteredUserSnapshot = {
    ...snapshot,
    memberships: [
      ...snapshot.memberships,
      {
        organization: {
          organizationId: membership.organizationId,
          name: membership.organizationName,
          shortCode: "",
          ownerId: "",
        },
        role: membership.role,
      },
    ],
    updatedAt: Date.now(),
  };

  await eventRepository.persistSnapshot({
    aggregateId: row.aggregate_id,
    aggregateType: "identity.user",
    version: row.version + 1,
    state: JSON.parse(JSON.stringify(updatedSnapshot)),
    createdAt: new Date(),
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
