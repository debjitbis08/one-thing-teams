import type {
  dependencies as UpdateStatusDependencies,
  statusUpdatedEvent as StatusUpdatedEvent,
} from "../application/UpdateTaskStatus.gen";
import type {
  dependencies as UpdateTaskDependencies,
  updatedEvent as UpdatedEvent,
} from "../application/UpdateTask.gen";
import type {
  dependencies as AssignDependencies,
  assignedEvent as AssignedEvent,
} from "../application/AssignTask.gen";
import type {
  dependencies as UnassignDependencies,
  unassignedEvent as UnassignedEvent,
} from "../application/UnassignTask.gen";
import {
  appendTaskStatusUpdatedEvent,
  appendTaskUpdatedEvent,
  appendTaskAssignedEvent,
  appendTaskUnassignedEvent,
} from "./TaskEventStore";
import { loadTaskAggregate } from "./TaskAggregateLoader";
import { memberExistsForOrg } from "./MemberLoader";

const loadTaskVersionAndStatus = async (taskId: string) => {
  const aggregate = await loadTaskAggregate(taskId);
  if (!aggregate) return undefined;
  return { version: aggregate.version, status: aggregate.status, kind: aggregate.kind };
};

const loadTaskVersion = async (taskId: string) => {
  const aggregate = await loadTaskAggregate(taskId);
  if (!aggregate) return undefined;
  return { version: aggregate.version };
};

export const updateTaskStatusBridgeFactory = (): UpdateStatusDependencies => ({
  now: () => Date.now(),
  loadTask: loadTaskVersionAndStatus,
  appendEvent: async (event: StatusUpdatedEvent) => {
    await appendTaskStatusUpdatedEvent({
      taskId: event.taskId,
      organizationId: event.organizationId,
      status: event.status,
      previousStatus: event.previousStatus,
      updatedBy: event.updatedBy,
      sessionId: event.sessionId,
      version: event.version,
      expectedVersion: event.expectedVersion,
      occurredAt: new Date(event.occurredAt),
    });
  },
});

export const updateTaskBridgeFactory = (): UpdateTaskDependencies => ({
  now: () => Date.now(),
  loadTask: loadTaskVersion,
  appendEvent: async (event: UpdatedEvent) => {
    await appendTaskUpdatedEvent({
      taskId: event.taskId,
      organizationId: event.organizationId,
      title: event.title ?? undefined,
      description: event.description ?? undefined,
      updatedBy: event.updatedBy,
      sessionId: event.sessionId,
      version: event.version,
      expectedVersion: event.expectedVersion,
      occurredAt: new Date(event.occurredAt),
    });
  },
});

export const assignTaskBridgeFactory = (organizationId: string): AssignDependencies => ({
  now: () => Date.now(),
  loadTask: loadTaskVersion,
  memberExists: async (userId: string) => {
    return memberExistsForOrg(userId, organizationId);
  },
  appendEvent: async (event: AssignedEvent) => {
    await appendTaskAssignedEvent({
      taskId: event.taskId,
      organizationId: event.organizationId,
      assigneeUserId: event.assigneeUserId,
      assignedBy: event.assignedBy,
      sessionId: event.sessionId,
      version: event.version,
      expectedVersion: event.expectedVersion,
      occurredAt: new Date(event.occurredAt),
    });
  },
});

export const unassignTaskBridgeFactory = (): UnassignDependencies => ({
  now: () => Date.now(),
  loadTask: loadTaskVersion,
  appendEvent: async (event: UnassignedEvent) => {
    await appendTaskUnassignedEvent({
      taskId: event.taskId,
      organizationId: event.organizationId,
      assigneeUserId: event.assigneeUserId,
      unassignedBy: event.unassignedBy,
      sessionId: event.sessionId,
      version: event.version,
      expectedVersion: event.expectedVersion,
      occurredAt: new Date(event.occurredAt),
    });
  },
});
