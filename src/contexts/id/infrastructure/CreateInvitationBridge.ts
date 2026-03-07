import type {
  dependencies as Dependencies,
  createdEvent as CreatedEvent,
} from "../application/CreateInvitation.gen";
import { appendInvitationCreatedEvent } from "./InvitationEventStore";
import { generateInvitationToken, hashInvitationToken } from "./InvitationTokenService";
import { loadOrganizationAggregate } from "./OrganizationAggregateLoader";

const getOrganizationName = async (organizationId: string): Promise<string | undefined> => {
  const aggregate = await loadOrganizationAggregate(organizationId);
  if (!aggregate) return undefined;

  // Walk events to find the latest name
  let name: string | undefined;
  for (const event of aggregate.events) {
    const data = event.data as Record<string, unknown>;
    if (typeof data.name === "string") {
      name = data.name;
    }
  }

  // If there's a snapshot, use its name as base (events override)
  if (!name && aggregate.snapshot) {
    name = (aggregate.snapshot.state as Record<string, unknown>).name as string;
  }

  return name;
};

export const createInvitationDependencies: Dependencies = {
  now: () => Date.now(),
  generateToken: () => generateInvitationToken(),
  hashToken: (token: string) => hashInvitationToken(token),
  appendEvent: async (event: CreatedEvent) => {
    await appendInvitationCreatedEvent(event);
  },
  organizationName: async (organizationId: string) => {
    const name = await getOrganizationName(organizationId);
    return name ?? undefined;
  },
};
