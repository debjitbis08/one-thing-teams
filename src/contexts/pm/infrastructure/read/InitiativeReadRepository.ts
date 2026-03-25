import { and, eq, asc } from "drizzle-orm";

import { db } from "../../../../infrastructure/db/client";
import { events } from "../../../../infrastructure/db/schema";

const aggregateType = "pm.initiative" as const;

type InitiativeCreatedData = {
  initiativeId: string;
  productId: string;
  organizationId: string;
  slug?: string;
  title: string;
  description: string | null;
  timeBudget: number;
  chatRoomLink: string | null;
  createdBy: string;
  occurredAt: string;
};

type ScoredData = {
  scoreType: string;
  userValue: { value: number; note: string | null } | null;
  timeCriticality: { value: number; note: string | null } | null;
  riskReduction: { value: number; note: string | null } | null;
  effort: { value: number; note: string | null } | null;
  isCore: boolean | null;
  contributionCount: number | null;
  scoredBy: string;
  occurredAt: string;
};

type ProgressStatusUpdatedData = {
  progressStatus: string;
  updatedBy: string;
  occurredAt: string;
};

type EvidenceItem = {
  kind: string;
  url?: string;
  description?: string;
  signedOffBy?: string;
  reason?: string;
};

type LifecycleStatusUpdatedData = {
  lifecycleStatus: string;
  evidence: EvidenceItem[];
  outcomeNotes: string | null;
  updatedBy: string;
  occurredAt: string;
};

type ScoreNote = { value: number; note: string | null };

export type InitiativeScore =
  | {
      scoreType: "proxy";
      userValue: ScoreNote;
      timeCriticality: ScoreNote;
      riskReduction: ScoreNote;
      effort: ScoreNote;
      isCore: boolean;
    }
  | {
      scoreType: "break_even";
      contributionCount: number;
      effort: ScoreNote;
      isCore: boolean;
    }
  | null;

export type InitiativeReadModel = {
  initiativeId: string;
  productId: string;
  slug: string;
  title: string;
  description: string | null;
  timeBudget: number;
  chatRoomLink: string | null;
  progressStatus: string;
  lifecycleStatus: string;
  score: InitiativeScore;
  evidence: EvidenceItem[];
  outcomeNotes: string | null;
  createdBy: string;
  createdAt: string;
};

type InitiativeState = {
  initiativeId: string;
  productId: string;
  slug: string;
  title: string;
  description: string | null;
  timeBudget: number;
  chatRoomLink: string | null;
  progressStatus: string;
  lifecycleStatus: string;
  score: InitiativeScore;
  evidence: EvidenceItem[];
  outcomeNotes: string | null;
  createdBy: string;
  createdAt: string;
};

function projectInitiative(eventRows: { type: string; data: unknown }[]): InitiativeState | null {
  let state: InitiativeState | null = null;

  for (const row of eventRows) {
    switch (row.type) {
      case "pm.initiative.created": {
        const d = row.data as InitiativeCreatedData;
        state = {
          initiativeId: d.initiativeId,
          productId: d.productId,
          slug: d.slug ?? d.title.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, ""),
          title: d.title,
          description: d.description,
          timeBudget: d.timeBudget,
          chatRoomLink: d.chatRoomLink,
          progressStatus: "thinking",
          lifecycleStatus: "waiting",
          score: null,
          evidence: [],
          outcomeNotes: null,
          createdBy: d.createdBy,
          createdAt: d.occurredAt,
        };
        break;
      }
      case "pm.initiative.scored": {
        if (!state) break;
        const d = row.data as ScoredData;
        if (d.scoreType === "proxy" && d.userValue && d.timeCriticality && d.riskReduction && d.effort) {
          state.score = {
            scoreType: "proxy",
            userValue: d.userValue,
            timeCriticality: d.timeCriticality,
            riskReduction: d.riskReduction,
            effort: d.effort,
            isCore: d.isCore ?? false,
          };
        } else if (d.scoreType === "break_even" && d.effort && d.contributionCount != null) {
          state.score = {
            scoreType: "break_even",
            contributionCount: d.contributionCount,
            effort: d.effort,
            isCore: d.isCore ?? false,
          };
        }
        break;
      }
      case "pm.initiative.progress_status_updated": {
        if (!state) break;
        const d = row.data as ProgressStatusUpdatedData;
        state.progressStatus = d.progressStatus;
        break;
      }
      case "pm.initiative.lifecycle_status_updated": {
        if (!state) break;
        const d = row.data as LifecycleStatusUpdatedData;
        state.lifecycleStatus = d.lifecycleStatus;
        state.evidence = d.evidence ?? [];
        state.outcomeNotes = d.outcomeNotes;
        break;
      }
    }
  }

  return state;
}

export async function listInitiativesForProduct(
  organizationId: string,
  productId: string,
): Promise<InitiativeReadModel[]> {
  // First find all initiative aggregate IDs for this product
  const createdRows = await db
    .select({ aggregateId: events.aggregateId, data: events.data })
    .from(events)
    .where(
      and(
        eq(events.orgId, organizationId),
        eq(events.aggregateType, aggregateType),
        eq(events.type, "pm.initiative.created"),
      ),
    )
    .orderBy(asc(events.createdAt));

  const initiativeIds = createdRows
    .filter(row => (row.data as InitiativeCreatedData).productId === productId)
    .map(row => row.aggregateId);

  if (initiativeIds.length === 0) return [];

  // Load all events for these initiatives in one query
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

  // Group events by aggregate
  const eventsByAggregate = new Map<string, { type: string; data: unknown }[]>();
  for (const row of allEvents) {
    if (!initiativeIds.includes(row.aggregateId)) continue;
    const list = eventsByAggregate.get(row.aggregateId) ?? [];
    list.push({ type: row.type, data: row.data });
    eventsByAggregate.set(row.aggregateId, list);
  }

  // Project each initiative
  const results: InitiativeReadModel[] = [];
  for (const id of initiativeIds) {
    const evts = eventsByAggregate.get(id);
    if (!evts) continue;
    const state = projectInitiative(evts);
    if (state) results.push(state);
  }

  return results;
}

export async function getInitiativeById(
  organizationId: string,
  initiativeId: string,
): Promise<InitiativeReadModel | null> {
  const rows = await db
    .select({ type: events.type, data: events.data })
    .from(events)
    .where(
      and(
        eq(events.aggregateId, initiativeId),
        eq(events.aggregateType, aggregateType),
        eq(events.orgId, organizationId),
      ),
    )
    .orderBy(asc(events.version));

  if (rows.length === 0) return null;

  return projectInitiative(rows);
}

export async function getInitiativeBySlug(
  organizationId: string,
  productId: string,
  slug: string,
): Promise<InitiativeReadModel | null> {
  const initiatives = await listInitiativesForProduct(organizationId, productId);
  return initiatives.find(i => i.slug === slug) ?? null;
}

export async function findSlugsWithPrefix(
  organizationId: string,
  slugPrefix: string,
  productId: string,
): Promise<string[]> {
  const createdRows = await db
    .select({ data: events.data })
    .from(events)
    .where(
      and(
        eq(events.orgId, organizationId),
        eq(events.aggregateType, aggregateType),
        eq(events.type, "pm.initiative.created"),
      ),
    );

  return createdRows
    .map(row => row.data as InitiativeCreatedData)
    .filter(d => d.productId === productId)
    .map(d => d.slug ?? d.title.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, ""))
    .filter(s => s === slugPrefix || s.startsWith(slugPrefix + "-"));
}
