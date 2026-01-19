import type { registeredUser } from "../domain/model/IdDomain.gen";
import { fetchRegisteredUserByIdentifier } from "./UserSnapshotRepository";
import { loadOrganizationAggregate } from "./OrganizationAggregateLoader";
import type { RenameOrganization_aggregateData as OrganizationAggregateData } from "../application/RenameOrganization.gen";

/**
 * Represents an organization with its current state loaded from the organization aggregate.
 * This ensures we always have the latest organization data even if user snapshots are stale.
 */
type HydratedOrganization = {
  organizationId: string;
  name: string;
  shortCode: string;
  ownerId: string;
};

/**
 * Loads organization state from the organization aggregate (snapshot + events).
 * This is proper event sourcing - we rebuild current state from events.
 */
async function loadCurrentOrganizationState(
  organizationId: string
): Promise<HydratedOrganization | null> {
  const aggregate = await loadOrganizationAggregate(organizationId);
  if (!aggregate) {
    return null;
  }

  // Start with snapshot state if available
  let currentState: HydratedOrganization | null = null;

  if (aggregate.snapshot) {
    currentState = {
      organizationId: aggregate.snapshot.state.organizationId,
      name: aggregate.snapshot.state.name,
      shortCode: aggregate.snapshot.state.shortCode,
      ownerId: aggregate.snapshot.state.ownerId,
    };
  }

  // Apply events that happened after the snapshot
  for (const event of aggregate.events) {
    if (!currentState && event.type_ === "identity.organization.created") {
      // Initialize from creation event
      const data = event.data as any;
      currentState = {
        organizationId: data.organizationId,
        name: data.name,
        shortCode: data.shortCode,
        ownerId: data.ownerId,
      };
    } else if (currentState && event.type_ === "identity.organization.renamed") {
      // Apply rename event
      const data = event.data as any;
      currentState = {
        ...currentState,
        name: data.name,
        shortCode: data.shortCode,
      };
    }
  }

  return currentState;
}

/**
 * Loads a user and hydrates organization data from organization aggregates.
 * This implements proper event sourcing by:
 * 1. Loading user snapshot (user aggregate state)
 * 2. Loading organization aggregates (replaying events)
 * 3. Combining them to produce current state
 *
 * This ensures we always return the latest organization names, even if
 * user snapshots haven't been updated.
 */
export async function loadUserWithCurrentOrganizations(
  identifier: string
): Promise<registeredUser | undefined> {
  try {
    const userSnapshot = await fetchRegisteredUserByIdentifier(identifier);
    if (!userSnapshot) {
      return undefined;
    }

    // Deep clone to avoid mutating the original
    const user = JSON.parse(JSON.stringify(userSnapshot)) as any;

    console.log("[UserAggregateLoader] Loading organizations for user");
    console.log("[UserAggregateLoader] User structure:", JSON.stringify(user, null, 2).substring(0, 500));

    // Extract organization IDs - try different structures
    const orgIds = new Set<string>();

    // Try direct access (from snapshot JSON)
    if (user.defaultOrganization?.organizationId) {
      console.log("[UserAggregateLoader] Found default org ID:", user.defaultOrganization.organizationId);
      orgIds.add(user.defaultOrganization.organizationId);
    }

    if (user.preferredOrganization?.organizationId) {
      console.log("[UserAggregateLoader] Found preferred org ID:", user.preferredOrganization.organizationId);
      orgIds.add(user.preferredOrganization.organizationId);
    }

    for (const membership of user.memberships || []) {
      if (membership.organization?.organizationId) {
        console.log("[UserAggregateLoader] Found membership org ID:", membership.organization.organizationId);
        orgIds.add(membership.organization.organizationId);
      }
    }

    console.log("[UserAggregateLoader] Total org IDs to load:", orgIds.size);

  // Load current organization states
  const orgStates = new Map<string, HydratedOrganization>();
  for (const orgId of orgIds) {
    const orgState = await loadCurrentOrganizationState(orgId);
    if (orgState) {
      orgStates.set(orgId, orgState);
    }
  }

  // Update organization data in the user structure
  if (user.defaultOrganization?.organizationId) {
    const orgState = orgStates.get(user.defaultOrganization.organizationId);
    if (orgState) {
      user.defaultOrganization.name = orgState.name;
      user.defaultOrganization.shortCode = orgState.shortCode;
    }
  }

  if (user.preferredOrganization?.organizationId) {
    const orgState = orgStates.get(user.preferredOrganization.organizationId);
    if (orgState) {
      user.preferredOrganization.name = orgState.name;
      user.preferredOrganization.shortCode = orgState.shortCode;
    }
  }

    for (const membership of user.memberships || []) {
      if (membership.organization?.organizationId) {
        const orgState = orgStates.get(membership.organization.organizationId);
        if (orgState) {
          membership.organization.name = orgState.name;
          membership.organization.shortCode = orgState.shortCode;
        }
      }
    }

    return user as any as registeredUser;
  } catch (error) {
    console.error("Error loading user with current organizations:", error);
    // Fall back to returning the user snapshot without hydration
    const userSnapshot = await fetchRegisteredUserByIdentifier(identifier);
    return userSnapshot;
  }
}
