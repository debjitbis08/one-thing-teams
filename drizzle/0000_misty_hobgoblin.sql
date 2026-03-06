CREATE TABLE "events" (
	"id" uuid PRIMARY KEY NOT NULL,
	"org_id" uuid NOT NULL,
	"aggregate_id" uuid NOT NULL,
	"aggregate_type" text NOT NULL,
	"version" integer NOT NULL,
	"type" text NOT NULL,
	"data" jsonb NOT NULL,
	"meta" jsonb DEFAULT '{}'::jsonb NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "events_aggregate_id_version_unique" UNIQUE("aggregate_id","version")
);
--> statement-breakpoint
CREATE TABLE "identity_sessions" (
	"id" text PRIMARY KEY NOT NULL,
	"user_id" uuid NOT NULL,
	"organization_id" uuid NOT NULL,
	"roles" text[] NOT NULL,
	"secret_hash" text NOT NULL,
	"ip_address" text,
	"user_agent" text,
	"last_verified_at" timestamp with time zone NOT NULL,
	"created_at" timestamp with time zone NOT NULL,
	"expires_at" timestamp with time zone NOT NULL
);
--> statement-breakpoint
CREATE TABLE "snapshots" (
	"aggregate_id" uuid NOT NULL,
	"aggregate_type" text NOT NULL,
	"version" integer NOT NULL,
	"state" jsonb NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "snapshots_aggregate_id_version_unique" UNIQUE("aggregate_id","version")
);
--> statement-breakpoint
CREATE INDEX "idx_events_agg" ON "events" USING btree ("aggregate_id","version");--> statement-breakpoint
CREATE INDEX "idx_events_org" ON "events" USING btree ("org_id");--> statement-breakpoint
CREATE INDEX "idx_events_created" ON "events" USING btree ("created_at");--> statement-breakpoint
CREATE INDEX "idx_events_agg_type" ON "events" USING btree ("aggregate_type");--> statement-breakpoint
CREATE INDEX "idx_identity_sessions_user" ON "identity_sessions" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "idx_identity_sessions_org" ON "identity_sessions" USING btree ("organization_id");--> statement-breakpoint
CREATE INDEX "idx_identity_sessions_expires_at" ON "identity_sessions" USING btree ("expires_at");