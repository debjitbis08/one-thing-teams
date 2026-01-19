type t = {
    organizationId: OrganizationId.organizationId,
    name: Organization.Name.t,
    shortCode: ShortCode.t,
    renamedBy: UserId.userId,
    expectedVersion: int,
    version: int,
    occurredAt: float,
}