import { jsonb, pgEnum, pgMaterializedView, pgTable, text, timestamp, uuid, integer } from "drizzle-orm/pg-core";
import { sql } from "drizzle-orm";

export const aggregateType = pgEnum("aggregate_type", ["identity.user", "identity.organization"]);

export const events = pgTable("events", {
  id: uuid("id").primaryKey(),
  orgId: uuid("org_id").notNull(),
  aggregateId: uuid("aggregate_id").notNull(),
  aggregateType: text("aggregate_type").notNull(),
  version: integer("version").notNull(),
  type: text("type").notNull(),
  data: jsonb("data").notNull(),
  meta: jsonb("meta").notNull().default(sql`'{}'::jsonb`),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
}, table => ({
  aggregateVersionIdx: table.unique("events_aggregate_id_version_unique").on(table.aggregateId, table.version),
  aggregateIdx: table.index("idx_events_agg").on(table.aggregateId, table.version),
  orgIdx: table.index("idx_events_org").on(table.orgId),
  createdIdx: table.index("idx_events_created").on(table.createdAt),
  aggregateTypeIdx: table.index("idx_events_agg_type").on(table.aggregateType),
}));

export const snapshots = pgTable("snapshots", {
  aggregateId: uuid("aggregate_id").notNull(),
  aggregateType: text("aggregate_type").notNull(),
  version: integer("version").notNull(),
  state: jsonb("state").notNull(),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
}, table => ({
  pk: table.primaryKey(table.aggregateId, table.version),
}));

export const latestSnapshots = pgMaterializedView("latest_snapshots", {
  aggregateId: uuid("aggregate_id").notNull(),
  aggregateType: text("aggregate_type").notNull(),
  version: integer("version").notNull(),
  state: jsonb("state").notNull(),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull(),
}).existing();
