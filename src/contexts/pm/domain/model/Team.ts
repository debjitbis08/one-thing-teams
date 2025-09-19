import { GlobalUniqueId } from "@foundation/domain/GlobalUniqueId";
import type { Organization, OrganizationId } from "./Organization";
import type { OrganizationMember } from "./OrganizationMember";

export class TeamId extends GlobalUniqueId {}

export class Team {
    readonly teamId: TeamId;
    orgId: OrganizationId;
    name: string;
    members: Set<OrganizationMember>;

    constructor(
        orgId: OrganizationId,
        name: string,
        members: Set<OrganizationMember> = new Set(),
        teamId?: TeamId
    ) {
        this.teamId = teamId ?? new TeamId();
        this.orgId = orgId;
        this.name = name;
        this.members = members;
    }

    rename(to: string) {
        this.name = to;
    }

    addMember(member: OrganizationMember) {
        if (member.organizationId.id !== this.orgId.id) {
            throw new Error(
                `Member ${member.userId.id} does not belong to organization ${this.orgId.id}`
            );
        }
        this.members.add(member);
    }

    removeMember(member: OrganizationMember) {
        this.members.delete(member);
    }

    hasMember(member: OrganizationMember): boolean {
        return this.members.has(member);
    }

    memberCount(): number {
        return this.members.size;
    }

    listMembers(): OrganizationMember[] {
        return Array.from(this.members);
    }
}