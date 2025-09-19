import { GlobalUniqueId } from '@foundation/domain/GlobalUniqueId';

export class OrganizationId extends GlobalUniqueId {}

export class Organization {
    readonly organizationId: OrganizationId;
    name: string;
    shortCode: string;

    constructor(name: string, shortCode: string, organizationId?: OrganizationId) {
        this.organizationId = organizationId ?? new OrganizationId();
        this.name = name;
        this.shortCode = shortCode;
    }

    rename(to: string) {
        this.name = to;
    }

    changeShortCode(to: string) {
        this.shortCode = to;
    }
}