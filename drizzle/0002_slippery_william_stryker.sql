ALTER TABLE "snapshots" DROP CONSTRAINT "snapshots_aggregate_id_version_unique";--> statement-breakpoint
DROP INDEX "idx_events_agg";--> statement-breakpoint
DROP INDEX "idx_events_created";--> statement-breakpoint
DROP INDEX "idx_events_agg_type";--> statement-breakpoint
ALTER TABLE "snapshots" ADD CONSTRAINT "snapshots_aggregate_id_version_pk" PRIMARY KEY("aggregate_id","version");--> statement-breakpoint
ALTER TABLE "snapshots" ADD COLUMN "org_id" uuid NOT NULL;--> statement-breakpoint
CREATE INDEX "idx_snapshots_org" ON "snapshots" USING btree ("org_id");--> statement-breakpoint
CREATE INDEX "idx_events_agg_type" ON "events" USING btree ("aggregate_type","aggregate_id");