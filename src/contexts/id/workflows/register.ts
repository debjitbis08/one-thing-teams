import { v7 as uuidv7 } from "uuid";

import type { dependencies as RegisterDependencies, registrationEvent } from "../application/RegisterWithPassword.gen";
import { defaultDependenciesJs } from "../web/RegisterUserController.gen";
import { eventRepository } from "../../../infrastructure/db/EventRepository";
import { storeRegisteredUserSnapshot } from "../infrastructure/UserSnapshotRepository";

const aggregateType = "identity.user" as const;
const registeredEventType = "identity.user.registered" as const;

const storeEvents: RegisterDependencies["storeEvents"] = async (event: registrationEvent) => {
  const eventId = uuidv7();

  await eventRepository.append({
    events: [
      {
        id: eventId,
        orgId: event.orgId,
        aggregateId: event.aggregateId,
        aggregateType,
        version: event.version,
        type: registeredEventType,
        data: {
          user: event.user,
          defaultOrganization: event.defaultOrganization,
          memberships: event.memberships,
          isContributor: event.isContributor,
          occurredAt: event.occurredAt,
        },
        meta: {},
        createdAt: new Date(event.occurredAt),
      },
    ],
    expectedVersion: event.version - 1,
  });
};

const storeSnapshot: RegisterDependencies["storeSnapshot"] = async (event, registeredUser) => {
  await storeRegisteredUserSnapshot(event, registeredUser);
};

export const registerDependencies: RegisterDependencies = {
  ...defaultDependenciesJs,
  storeEvents,
  storeSnapshot,
};
