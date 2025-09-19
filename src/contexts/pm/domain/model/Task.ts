import { FibonacciScale } from "@common/domain/FibonacciScale";
import { GlobalUniqueId } from "@foundation/domain/GlobalUniqueId";
import { ErrorTypes } from "@utilities/ErrorTypes";
import { SystemError } from "@utilities/SystemError";
import { Either, Left, Right } from "purify-ts/Either";
import type { InitiativeId } from "./Initiative";
import type { OrganizationMember } from "./OrganizationMember";
import type { TeamId } from "./Team";
import { TaskStatus } from "./TaskStatus";

const permittedTransitions: Record<TaskStatus, TaskStatus[]> = {
    [TaskStatus.Todo]: [TaskStatus.Doing, TaskStatus.Stuck],
    [TaskStatus.Doing]: [TaskStatus.Stuck, TaskStatus.Done],
    [TaskStatus.Stuck]: [TaskStatus.Doing, TaskStatus.Done],
    [TaskStatus.Done]: [TaskStatus.Doing],
};

const activeStatuses = new Set([TaskStatus.Doing, TaskStatus.Stuck, TaskStatus.Done]);

export interface TaskTeamContext {
    teamId: TeamId;
    members: ReadonlyArray<OrganizationMember>;
}

export type TaskResult = Either<SystemError, Task>;

export class TaskId extends GlobalUniqueId {}

export class Task {
    readonly taskId: TaskId;
    initiativeId: InitiativeId;
    title: string;
    description?: string;
    status: TaskStatus;
    priority: FibonacciScale;
    isOptional: boolean;
    startedAt?: Date;
    completedAt?: Date;

    private assignees: Map<string, OrganizationMember>;
    private teamId?: TeamId;
    private allowedAssigneeIds?: Set<string>;

    private constructor(
        initiativeId: InitiativeId,
        title: string,
        priority: FibonacciScale,
        status: TaskStatus,
        description: string | undefined,
        isOptional: boolean,
        startedAt: Date | undefined,
        completedAt: Date | undefined,
        teamContext: TaskTeamContext | undefined,
        taskId?: TaskId
    ) {
        this.taskId = taskId ?? new TaskId();
        this.initiativeId = initiativeId;
        this.title = title;
        this.description = description;
        this.priority = priority;
        this.status = status;
        this.isOptional = isOptional;
        this.startedAt = startedAt;
        this.completedAt = completedAt;

        this.assignees = new Map();
        this.setTeamContext(teamContext);
    }

    static create(params: {
        initiativeId: InitiativeId;
        title: string;
        priority: FibonacciScale;
        status?: TaskStatus;
        description?: string;
        isOptional?: boolean;
        assignees?: ReadonlyArray<OrganizationMember>;
        startedAt?: Date;
        completedAt?: Date;
        teamContext?: TaskTeamContext;
        taskId?: TaskId;
    }): TaskResult {
        const {
            initiativeId,
            title,
            priority,
            status = TaskStatus.Todo,
            description,
            isOptional = false,
            assignees = [],
            startedAt,
            completedAt,
            teamContext,
            taskId,
        } = params;

        const task = new Task(
            initiativeId,
            title,
            priority,
            status,
            description,
            isOptional,
            startedAt ?? (status === TaskStatus.Doing ? new Date() : undefined),
            completedAt ?? (status === TaskStatus.Done ? new Date() : undefined),
            teamContext,
            taskId
        );

        const initialAssigneesResult = task.applyInitialAssignees(assignees);
        if (initialAssigneesResult.isLeft()) {
            return initialAssigneesResult;
        }

        if (activeStatuses.has(status) && task.assigneeCount() === 0) {
            return Left(
                new SystemError(
                    "Tasks in progress must have at least one assignee",
                    ErrorTypes.ValidationError
                )
            );
        }

        return Right(task);
    }

    addAssignee(member: OrganizationMember): TaskResult {
        const verifyAssignee = this.validateAssignee(member);
        if (verifyAssignee.isLeft()) {
            return verifyAssignee;
        }

        const key = Task.memberKey(member);
        if (!this.assignees.has(key)) {
            this.assignees.set(key, member);
        }

        return Right(this);
    }

    removeAssignee(member: OrganizationMember): TaskResult {
        const key = Task.memberKey(member);

        if (!this.assignees.has(key)) {
            return Right(this);
        }

        if (this.assignees.size === 1 && activeStatuses.has(this.status)) {
            return Left(
                new SystemError(
                    "Active tasks must retain at least one assignee",
                    ErrorTypes.ValidationError
                )
            );
        }

        this.assignees.delete(key);
        return Right(this);
    }

    hasAssignee(member: OrganizationMember): boolean {
        return this.assignees.has(Task.memberKey(member));
    }

    assigneeCount(): number {
        return this.assignees.size;
    }

    listAssignees(): OrganizationMember[] {
        return Array.from(this.assignees.values());
    }

    rename(to: string) {
        this.title = to;
    }

    updateDescription(to: string) {
        this.description = to;
    }

    updatePriority(to: FibonacciScale) {
        this.priority = to;
    }

    updateStatus(to: TaskStatus): TaskResult {
        if (!permittedTransitions[this.status].includes(to) && to !== this.status) {
            return Left(
                new SystemError(
                    `Cannot transition task from ${this.status} to ${to}`,
                    ErrorTypes.ValidationError
                )
            );
        }

        if (activeStatuses.has(to) && this.assigneeCount() === 0) {
            return Left(
                new SystemError(
                    "Tasks in progress must have at least one assignee",
                    ErrorTypes.ValidationError
                )
            );
        }

        this.status = to;

        if (to === TaskStatus.Doing && !this.startedAt) {
            this.startedAt = new Date();
        }

        if (to === TaskStatus.Done) {
            this.completedAt = new Date();
        } else if (this.completedAt && to !== TaskStatus.Done) {
            this.completedAt = undefined;
        }

        if (to === TaskStatus.Todo) {
            this.startedAt = undefined;
        }

        return Right(this);
    }

    markOptional() {
        this.isOptional = true;
    }

    markEssential() {
        this.isOptional = false;
    }

    getPriorityScore(): number {
        return this.priority.getValue();
    }

    static sortByPriority(tasks: Task[]): Task[] {
        return tasks.sort((a, b) => {
            if (a.isOptional !== b.isOptional) {
                return a.isOptional ? 1 : -1;
            }

            return b.getPriorityScore() - a.getPriorityScore();
        });
    }

    updateTeamContext(teamContext: TaskTeamContext): TaskResult {
        const proposedAllowedIds = new Set(
            teamContext.members.map((member) => Task.memberKey(member))
        );

        const invalid = this.listAssignees().filter(
            (member) => !proposedAllowedIds.has(Task.memberKey(member))
        );

        if (invalid.length > 0) {
            return Left(
                new SystemError(
                    "Existing assignees are not part of the assigned team",
                    ErrorTypes.ValidationError
                )
            );
        }

        this.teamId = teamContext.teamId;
        this.allowedAssigneeIds = proposedAllowedIds;

        if (activeStatuses.has(this.status) && this.assigneeCount() === 0) {
            return Left(
                new SystemError(
                    "Tasks in progress must have at least one assignee",
                    ErrorTypes.ValidationError
                )
            );
        }

        return Right(this);
    }

    private applyInitialAssignees(initialAssignees: ReadonlyArray<OrganizationMember>): TaskResult {
        if (initialAssignees.length === 0) {
            return Right(this);
        }

        const seen = new Set<string>();

        for (const member of initialAssignees) {
            const validation = this.validateAssignee(member);
            if (validation.isLeft()) {
                return validation;
            }

            const key = Task.memberKey(member);
            if (seen.has(key)) {
                return Left(
                    new SystemError(
                        "Duplicate assignees are not allowed",
                        ErrorTypes.ValidationError
                    )
                );
            }

            seen.add(key);
        }

        for (const member of initialAssignees) {
            this.assignees.set(Task.memberKey(member), member);
        }

        return Right(this);
    }

    private validateAssignee(member: OrganizationMember): TaskResult {
        if (!this.teamId || !this.allowedAssigneeIds) {
            return Left(
                new SystemError(
                    "Cannot assign members until the initiative has an assigned team",
                    ErrorTypes.ValidationError
                )
            );
        }

        const memberKey = Task.memberKey(member);

        if (!this.allowedAssigneeIds.has(memberKey)) {
            return Left(
                new SystemError(
                    `Member ${member.userId.id} is not part of team ${this.teamId.id} assigned to this initiative`,
                    ErrorTypes.ValidationError
                )
            );
        }

        return Right(this);
    }

    private setTeamContext(teamContext: TaskTeamContext | undefined) {
        if (!teamContext) {
            this.teamId = undefined;
            this.allowedAssigneeIds = undefined;
            return;
        }

        this.teamId = teamContext.teamId;
        this.allowedAssigneeIds = new Set(
            teamContext.members.map((member) => Task.memberKey(member))
        );
    }

    private static memberKey(member: OrganizationMember): string {
        return member.userId.id;
    }
}
