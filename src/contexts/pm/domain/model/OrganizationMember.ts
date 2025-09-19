import type { UserId } from "@common/domain/UserId";
import type { OrganizationId } from "./Organization";
import type { Email } from "@common/domain/Email";

export class OrganizationMember {
    organizationId: OrganizationId;
    userId: UserId;
    name: string;
    email: Email;

    constructor(
        organizationId: OrganizationId,
        userId: UserId,
        name: string,
        email: Email
    ) {
        this.organizationId = organizationId;
        this.userId = userId;
        this.name = name;
        this.email = email;
    }
}