import type {
  dependencies as Dependencies,
  revokedEvent as RevokedEvent,
} from "../application/RevokeInvitation.gen";
import { appendInvitationRevokedEvent } from "./InvitationEventStore";
import { loadInvitationAggregate } from "./InvitationAggregateLoader";

export const revokeInvitationDependencies: Dependencies = {
  now: () => Date.now(),
  loadAggregate: async (invitationId: string) => {
    const aggregate = await loadInvitationAggregate(invitationId);
    return aggregate ?? undefined;
  },
  appendEvent: async (event: RevokedEvent) => {
    await appendInvitationRevokedEvent(event);
  },
};
