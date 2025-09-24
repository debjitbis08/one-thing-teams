CREATE TABLE IF NOT EXISTS events (
  id UUID PRIMARY KEY,
  org_id UUID NOT NULL,
  aggregate_id UUID NOT NULL,
  aggregate_type TEXT NOT NULL,
  version INTEGER NOT NULL,
  type TEXT NOT NULL,
  data JSONB NOT NULL,
  meta JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (aggregate_id, version)
);

CREATE INDEX IF NOT EXISTS idx_events_agg ON events (aggregate_id, version);
CREATE INDEX IF NOT EXISTS idx_events_org ON events (org_id);
CREATE INDEX IF NOT EXISTS idx_events_created ON events (created_at);
CREATE INDEX IF NOT EXISTS idx_events_agg_type ON events (aggregate_type);

CREATE TABLE IF NOT EXISTS snapshots (
  aggregate_id UUID NOT NULL,
  aggregate_type TEXT NOT NULL,
  version INTEGER NOT NULL,
  state JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (aggregate_id, version)
);

CREATE MATERIALIZED VIEW latest_snapshots AS
  SELECT DISTINCT ON (aggregate_id)
    aggregate_id,
    aggregate_type,
    version,
    state,
    created_at
  FROM snapshots
  ORDER BY aggregate_id, version DESC;

CREATE UNIQUE INDEX idx_latest_snapshots_agg ON latest_snapshots (aggregate_id);
