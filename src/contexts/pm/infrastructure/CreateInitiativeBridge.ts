import type {
  dependencies as Dependencies,
  createdEvent as CreatedEvent,
} from "../application/CreateInitiative.gen";
import { appendInitiativeCreatedEvent } from "./InitiativeEventStore";
import { productExistsForOrg } from "./ProductAggregateLoader";
import { findSlugsWithPrefix } from "./read/InitiativeReadRepository";

export const createInitiativeBridgeFactory = (organizationId: string): Dependencies => ({
  now: () => Date.now(),
  productExists: async (productId: string) => {
    return productExistsForOrg(productId, organizationId);
  },
  findSlugsWithPrefix: async (slugPrefix: string, productId: string) => {
    return findSlugsWithPrefix(organizationId, slugPrefix, productId);
  },
  appendEvent: async (event: CreatedEvent) => {
    await appendInitiativeCreatedEvent(event);
  },
});
