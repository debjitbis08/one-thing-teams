import { GlobalUniqueId } from "@foundation/domain/GlobalUniqueId";
import { LifecycleStatus } from "./LifecycleStatus";
import type { ProductId } from "./Product";
import { ProgressStatus } from "./ProgressStatus";
import type { TeamId } from "./Team";
import { InitiativePriority } from "./InitiativePriority";

export class InitiativeId extends GlobalUniqueId {}

export class Initiative {
    readonly initiativeId: InitiativeId;
    productId: ProductId;
    title: string;
    description?: string;
    timeBudget: number;
    chatRoomLink?: string;
    progressStatus: ProgressStatus;
    lifecycleStatus: LifecycleStatus;
    isValidated: boolean;
    validationEvidence?: string;
    outcomeNotes?: string;
    assignedTeamId?: TeamId;
    priority: InitiativePriority;

    constructor(
        productId: ProductId,
        title: string,
        timeBudget: number,
        priority: InitiativePriority,
        description?: string,
        chatRoomLink?: string,
        progressStatus: ProgressStatus = ProgressStatus.Thinking,
        lifecycleStatus: LifecycleStatus = LifecycleStatus.Waiting,
        isValidated = false,
        validationEvidence?: string,
        outcomeNotes?: string,
        assignedTeamId?: TeamId,
        initiativeId?: InitiativeId
    ) {
        this.initiativeId = initiativeId ?? new InitiativeId();
        this.productId = productId;
        this.title = title;
        this.description = description;
        this.timeBudget = timeBudget;
        this.chatRoomLink = chatRoomLink;
        this.progressStatus = progressStatus;
        this.lifecycleStatus = lifecycleStatus;
        this.isValidated = isValidated;
        this.validationEvidence = validationEvidence;
        this.outcomeNotes = outcomeNotes;
        this.assignedTeamId = assignedTeamId;
        this.priority = priority;
    }


    static sortByPriority(initiatives: Initiative[]): Initiative[] {
        return initiatives.sort((a, b) => InitiativePriority.compare(a.priority, b.priority));
    }

    assignToTeam(teamId: TeamId) {
        this.assignedTeamId = teamId;
    }

    unassignTeam() {
        this.assignedTeamId = undefined;
    }

    updateProgressStatus(to: ProgressStatus) {
        this.progressStatus = to;
    }

    updateLifecycleStatus(to: LifecycleStatus) {
        this.lifecycleStatus = to;
    }

    validate(evidence?: string) {
        this.isValidated = true;
        this.validationEvidence = evidence;
    }

    invalidate() {
        this.isValidated = false;
        this.validationEvidence = undefined;
    }

    addOutcomeNotes(notes: string) {
        this.outcomeNotes = notes;
    }

    updatePriority(newPriority: InitiativePriority) {
        this.priority = newPriority;
    }

    rename(to: string) {
        this.title = to;
    }

    updateDescription(to: string) {
        this.description = to;
    }

    updateTimeBudget(to: number) {
        this.timeBudget = to;
    }

    updateChatRoomLink(to: string) {
        this.chatRoomLink = to;
    }

}