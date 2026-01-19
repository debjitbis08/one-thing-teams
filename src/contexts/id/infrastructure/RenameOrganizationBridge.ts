import type {
  dependencies,
  RenameOrganization_renameEvent as RenameOrganizationEvent,
} from "../web/RenameOrganizationController.gen";
import { appendOrganizationRenamedEvent } from "./OrganizationEventStore";
import { loadOrganizationAggregate } from "./OrganizationAggregateLoader";
import { updateOrganizationInUserSnapshots } from "./UserSnapshotRepository";

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

  // Update user snapshots that reference this organization
  // This is a materialized view pattern: user snapshots contain denormalized
  // organization data for performance. When organizations change, we update
  // all affected user snapshots to maintain consistency.
  try {
    await updateOrganizationInUserSnapshots(
      event.organizationId,
      event.name,
      event.shortCode,
    );
  } catch (error) {
    console.error("Failed to update user snapshots after organization rename:", error);
    // Log but don't fail - the rename event is already persisted
  }
};

export const renameOrganizationDependencies: dependencies = {
  appendEvent: appendRenameEvent,
  loadAggregate: async organizationId => {
    const aggregate = await loadOrganizationAggregate(organizationId);
    return aggregate ?? undefined;
  },
  now: () => Date.now(),
};
