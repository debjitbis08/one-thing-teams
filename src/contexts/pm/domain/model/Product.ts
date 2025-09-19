import { GlobalUniqueId } from "@foundation/domain/GlobalUniqueId";
import type { OrganizationId } from "./Organization";

export class ProductId extends GlobalUniqueId {}

export class Product {
  readonly productId: ProductId;
  orgId: OrganizationId;
  name: string;
  shortCode: string;
  description?: string;

  constructor(
    orgId: OrganizationId,
    name: string,
    shortCode: string,
    productId?: ProductId,
    description?: string
  ) {
    this.productId = productId ?? new ProductId();
    this.orgId = orgId;
    this.name = name;
    this.shortCode = shortCode;
    this.description = description;
  }
}