import { jsonb, pgMaterializedView, pgTable, text, timestamp, uuid, integer } from "drizzle-orm/pg-core";
import { sql } from "drizzle-orm";

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
});

export const snapshots = pgTable("snapshots", {
  aggregateId: uuid("aggregate_id").notNull(),
  aggregateType: text("aggregate_type").notNull(),
  version: integer("version").notNull(),
  state: jsonb("state").notNull(),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
});

export const latestSnapshots = pgMaterializedView("latest_snapshots", {
  aggregateId: uuid("aggregate_id").notNull(),
  aggregateType: text("aggregate_type").notNull(),
  version: integer("version").notNull(),
  state: jsonb("state").notNull(),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull(),
}).existing();
