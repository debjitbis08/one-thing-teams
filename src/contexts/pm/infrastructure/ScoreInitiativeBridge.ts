import type {
  dependencies as Dependencies,
  scoredEvent as ScoredEvent,
} from "../application/ScoreInitiative.gen";
import { appendInitiativeScoredEvent } from "./InitiativeEventStore";
import { loadInitiativeAggregate } from "./InitiativeAggregateLoader";

const appendScoredEvent = async (event: ScoredEvent) => {
  const occurredAt = new Date(event.occurredAt);

  await appendInitiativeScoredEvent({
    initiativeId: event.initiativeId,
    organizationId: event.organizationId,
    scoreType: event.scoreType,
    userValue: event.userValue ?? undefined,
    timeCriticality: event.timeCriticality ?? undefined,
    riskReduction: event.riskReduction ?? undefined,
    effort: event.effort ?? undefined,
    isCore: event.isCore ?? undefined,
    contributionCount: event.contributionCount ?? undefined,
    scoredBy: event.scoredBy,
    sessionId: event.sessionId,
    version: event.version,
    expectedVersion: event.expectedVersion,
    occurredAt,
  });
};

export const scoreInitiativeBridgeFactory = (): Dependencies => ({
  now: () => Date.now(),
  loadAggregate: async (initiativeId: string) => {
    const aggregate = await loadInitiativeAggregate(initiativeId);
    return aggregate ?? undefined;
  },
  appendEvent: appendScoredEvent,
});
