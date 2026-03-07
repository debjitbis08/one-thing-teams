import type {
  dependencies as Dependencies,
  createdEvent as CreatedEvent,
} from "../application/CreateInitiative.gen";
import { appendInitiativeCreatedEvent } from "./InitiativeEventStore";
import { productExistsForOrg } from "./ProductAggregateLoader";

export const createInitiativeBridgeFactory = (organizationId: string): Dependencies => ({
  now: () => Date.now(),
  productExists: async (productId: string) => {
    return productExistsForOrg(productId, organizationId);
  },
  appendEvent: async (event: CreatedEvent) => {
    await appendInitiativeCreatedEvent(event);
  },
});
