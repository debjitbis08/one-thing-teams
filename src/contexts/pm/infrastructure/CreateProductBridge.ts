import type {
  dependencies as Dependencies,
  createdEvent as CreatedEvent,
} from "../application/CreateProduct.gen";
import { appendProductCreatedEvent } from "./ProductEventStore";

export const createProductDependencies: Dependencies = {
  now: () => Date.now(),
  appendEvent: async (event: CreatedEvent) => {
    await appendProductCreatedEvent(event);
  },
};
