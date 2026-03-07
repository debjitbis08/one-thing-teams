import {
  index,
  integer,
  jsonb,
  pgMaterializedView,
  pgTable,
  primaryKey,
  text,
  timestamp,
  unique,
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
  t => [
    unique().on(t.aggregateId, t.version),
    index("idx_events_org").on(t.orgId),
    index("idx_events_agg_type").on(t.aggregateType, t.aggregateId),
  ],
);

export const snapshots = pgTable(
  "snapshots",
  {
    aggregateId: uuid("aggregate_id").notNull(),
    aggregateType: text("aggregate_type").notNull(),
    orgId: uuid("org_id").notNull(),
    version: integer("version").notNull(),
    state: jsonb("state").notNull(),
    createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
  },
  t => [
    primaryKey({ columns: [t.aggregateId, t.version] }),
    index("idx_snapshots_org").on(t.orgId),
  ],
);

export const latestSnapshots = pgMaterializedView("latest_snapshots", {
  aggregateId: uuid("aggregate_id").notNull(),
  aggregateType: text("aggregate_type").notNull(),
  version: integer("version").notNull(),
  state: jsonb("state").notNull(),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull(),
}).existing();

export const identitySessions = pgTable(
  "identity_sessions",
  {
    id: text("id").primaryKey(),
    userId: uuid("user_id").notNull(),
    organizationId: uuid("organization_id").notNull(),
    roles: text("roles").array().notNull(),
    secretHash: text("secret_hash").notNull(),
    ipAddress: text("ip_address"),
    userAgent: text("user_agent"),
    lastVerifiedAt: timestamp("last_verified_at", { withTimezone: true }).notNull(),
    createdAt: timestamp("created_at", { withTimezone: true }).notNull(),
    expiresAt: timestamp("expires_at", { withTimezone: true }).notNull(),
  },
  t => [
    index("idx_identity_sessions_user").on(t.userId),
    index("idx_identity_sessions_org").on(t.organizationId),
    index("idx_identity_sessions_expires_at").on(t.expiresAt),
  ],
);
