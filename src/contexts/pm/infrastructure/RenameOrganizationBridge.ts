import type {
  dependencies,
  RenameOrganization_renameEvent as RenameOrganizationEvent,
} from "../web/RenameOrganizationController.gen";
import { appendOrganizationRenamedEvent } from "../../id/infrastructure/OrganizationEventStore";
import { loadOrganizationAggregate } from "../../id/infrastructure/OrganizationAggregateLoader";

const appendRenameEvent = async (event: RenameOrganizationEvent) => {
  const occurredAt = new Date(event.occurredAt);

  await appendOrganizationRenamedEvent({
    organizationId: event.organizationId,
    name: event.name,
    shortCode: event.shortCode,
    renamedBy: event.renamedBy,
    sessionId: event.sessionId,
    version: event.version,
    expectedVersion: event.expectedVersion,
    occurredAt,
  });
};

export const renameOrganizationDependencies: dependencies = {
  appendEvent: appendRenameEvent,
  loadAggregate: async organizationId => {
    const aggregate = await loadOrganizationAggregate(organizationId);
    return aggregate ?? undefined;
  },
  now: () => Date.now(),
};
