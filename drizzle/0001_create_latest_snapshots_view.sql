CREATE MATERIALIZED VIEW IF NOT EXISTS latest_snapshots AS
  SELECT DISTINCT ON (aggregate_id)
    aggregate_id,
    aggregate_type,
    version,
    state,
    created_at
  FROM snapshots
  ORDER BY aggregate_id, version DESC;

CREATE UNIQUE INDEX IF NOT EXISTS idx_latest_snapshots_agg ON latest_snapshots (aggregate_id);