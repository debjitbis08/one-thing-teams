import {
  index,
  integer,
  jsonb,
  pgMaterializedView,
  pgTable,
  primaryKey,
  text,
  timestamp,
  uniqueIndex,
  uuid,
} from "drizzle-orm/pg-core";
import { sql } from "drizzle-orm";

export const events = pgTable(
  "events",
  {
    id: uuid("id").primaryKey(),
    orgId: uuid("org_id").notNull(),
    aggregateId: uuid("aggregate_id").notNull(),
    aggregateType: text("aggregate_type").notNull(),
    version: integer("version").notNull(),
    type: text("type").notNull(),
    data: jsonb("data").notNull(),
    meta: jsonb("meta").notNull().default(sql`'{}'::jsonb`),
    createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
  },
  table => ({
    aggregateVersionIdx: uniqueIndex("events_aggregate_id_version_unique").on(
      table.aggregateId,
      table.version,
    ),
    aggregateIdx: index("idx_events_agg").on(table.aggregateId, table.version),
    orgIdx: index("idx_events_org").on(table.orgId),
    createdIdx: index("idx_events_created").on(table.createdAt),
    aggregateTypeIdx: index("idx_events_agg_type").on(table.aggregateType),
  }),
);

export const snapshots = pgTable(
  "snapshots",
  {
    aggregateId: uuid("aggregate_id").notNull(),
    aggregateType: text("aggregate_type").notNull(),
    version: integer("version").notNull(),
    state: jsonb("state").notNull(),
    createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
  },
  table => ({
    pk: primaryKey({ columns: [table.aggregateId, table.version] }),
  }),
);

export const latestSnapshots = pgMaterializedView("latest_snapshots", {
  aggregateId: uuid("aggregate_id").notNull(),
  aggregateType: text("aggregate_type").notNull(),
  version: integer("version").notNull(),
  state: jsonb("state").notNull(),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull(),
}).existing();
