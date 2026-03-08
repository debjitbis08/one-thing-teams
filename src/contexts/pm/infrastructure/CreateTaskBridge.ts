import type {
  dependencies as Dependencies,
  createdEvent as CreatedEvent,
} from "../application/CreateTask.gen";
import { appendTaskCreatedEvent } from "./TaskEventStore";
import { productExistsForOrg, initiativeExistsForOrg, emergencyExistsForOrg } from "./ProductAggregateLoader";

export const createTaskBridgeFactory = (organizationId: string): Dependencies => ({
  now: () => Date.now(),
  initiativeExists: async (initiativeId: string) => {
    return initiativeExistsForOrg(initiativeId, organizationId);
  },
  productExists: async (productId: string) => {
    return productExistsForOrg(productId, organizationId);
  },
  emergencyExists: async (emergencyId: string) => {
    return emergencyExistsForOrg(emergencyId, organizationId);
  },
  appendEvent: async (event: CreatedEvent) => {
    await appendTaskCreatedEvent(event);
  },
});
