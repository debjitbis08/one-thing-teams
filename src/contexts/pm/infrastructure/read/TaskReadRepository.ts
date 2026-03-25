import { and, eq, asc } from "drizzle-orm";

import { db } from "../../../../infrastructure/db/client";
import { events } from "../../../../infrastructure/db/schema";

const aggregateType = "pm.task" as const;

type TaskCreatedData = {
  taskId: string;
  organizationId: string;
  title: string;
  description: string | null;
  kind: string;
  initiativeId: string | null;
  productId: string | null;
  emergencyId: string | null;
  scenarios: { title: string; acceptanceCriteria: string[] }[] | null;
  createdBy: string;
  occurredAt: string;
};

type TaskUpdatedData = {
  taskId: string;
  title: string | null;
  description: string | null;
  updatedBy: string;
  occurredAt: string;
};

type TaskStatusUpdatedData = {
  taskId: string;
  status: string;
  previousStatus: string;
  updatedBy: string;
  occurredAt: string;
};

type ScenarioAddedData = {
  taskId: string;
  scenarioId: string;
  title: string;
  addedBy: string;
  occurredAt: string;
};

type ScenarioRemovedData = {
  taskId: string;
  scenarioId: string;
  removedBy: string;
  occurredAt: string;
};

type TaskAssignedData = {
  taskId: string;
  assigneeUserId: string;
  assignedBy: string;
  occurredAt: string;
};

type TaskUnassignedData = {
  taskId: string;
  assigneeUserId: string;
  unassignedBy: string;
  occurredAt: string;
};

export type ScenarioReadModel = {
  scenarioId: string;
  title: string;
};

export type TaskReadModel = {
  taskId: string;
  title: string;
  description: string | null;
  kind: string;
  initiativeId: string | null;
  productId: string | null;
  emergencyId: string | null;
  status: string;
  assignees: string[];
  scenarios: ScenarioReadModel[];
  createdBy: string;
  createdAt: string;
};

type TaskState = TaskReadModel;

function projectTask(eventRows: { type: string; data: unknown }[]): TaskState | null {
  let state: TaskState | null = null;

  for (const row of eventRows) {
    switch (row.type) {
      case "pm.task.created": {
        const d = row.data as TaskCreatedData;
        state = {
          taskId: d.taskId,
          title: d.title,
          description: d.description,
          kind: d.kind,
          initiativeId: d.initiativeId,
          productId: d.productId,
          emergencyId: d.emergencyId,
          status: "todo",
          assignees: [],
          scenarios: (d.scenarios ?? []).map((s, i) => ({
            scenarioId: `initial-${i}`,
            title: s.title,
          })),
          createdBy: d.createdBy,
          createdAt: d.occurredAt,
        };
        break;
      }
      case "pm.task.updated": {
        if (!state) break;
        const d = row.data as TaskUpdatedData;
        if (d.title != null) state.title = d.title;
        if (d.description != null) state.description = d.description;
        break;
      }
      case "pm.task.status_updated": {
        if (!state) break;
        const d = row.data as TaskStatusUpdatedData;
        state.status = d.status;
        break;
      }
      case "pm.task.scenario_added": {
        if (!state) break;
        const d = row.data as ScenarioAddedData;
        state.scenarios.push({
          scenarioId: d.scenarioId,
          title: d.title,
        });
        break;
      }
      case "pm.task.scenario_removed": {
        if (!state) break;
        const d = row.data as ScenarioRemovedData;
        state.scenarios = state.scenarios.filter(s => s.scenarioId !== d.scenarioId);
        break;
      }
      case "pm.task.assigned": {
        if (!state) break;
        const d = row.data as TaskAssignedData;
        if (!state.assignees.includes(d.assigneeUserId)) {
          state.assignees.push(d.assigneeUserId);
        }
        break;
      }
      case "pm.task.unassigned": {
        if (!state) break;
        const d = row.data as TaskUnassignedData;
        state.assignees = state.assignees.filter(id => id !== d.assigneeUserId);
        break;
      }
    }
  }

  return state;
}

export async function listTasksForInitiative(
  organizationId: string,
  initiativeId: string,
): Promise<TaskReadModel[]> {
  // Find all task aggregate IDs created for this initiative
  const createdRows = await db
    .select({ aggregateId: events.aggregateId, data: events.data })
    .from(events)
    .where(
      and(
        eq(events.orgId, organizationId),
        eq(events.aggregateType, aggregateType),
        eq(events.type, "pm.task.created"),
      ),
    )
    .orderBy(asc(events.createdAt));

  const taskIds = createdRows
    .filter(row => (row.data as TaskCreatedData).initiativeId === initiativeId)
    .map(row => row.aggregateId);

  if (taskIds.length === 0) return [];

  // Load all events for these tasks
  const allEvents = await db
    .select({
      aggregateId: events.aggregateId,
      type: events.type,
      data: events.data,
      version: events.version,
    })
    .from(events)
    .where(
      and(
        eq(events.orgId, organizationId),
        eq(events.aggregateType, aggregateType),
      ),
    )
    .orderBy(asc(events.version));

  // Group by aggregate
  const eventsByAggregate = new Map<string, { type: string; data: unknown }[]>();
  for (const row of allEvents) {
    if (!taskIds.includes(row.aggregateId)) continue;
    const list = eventsByAggregate.get(row.aggregateId) ?? [];
    list.push({ type: row.type, data: row.data });
    eventsByAggregate.set(row.aggregateId, list);
  }

  // Project each task
  const results: TaskReadModel[] = [];
  for (const id of taskIds) {
    const evts = eventsByAggregate.get(id);
    if (!evts) continue;
    const state = projectTask(evts);
    if (state) results.push(state);
  }

  return results;
}

export async function getTaskById(
  organizationId: string,
  taskId: string,
): Promise<TaskReadModel | null> {
  const rows = await db
    .select({ type: events.type, data: events.data })
    .from(events)
    .where(
      and(
        eq(events.aggregateId, taskId),
        eq(events.aggregateType, aggregateType),
        eq(events.orgId, organizationId),
      ),
    )
    .orderBy(asc(events.version));

  if (rows.length === 0) return null;

  return projectTask(rows);
}
