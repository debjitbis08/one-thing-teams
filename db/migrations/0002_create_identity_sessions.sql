CREATE UNLOGGED TABLE IF NOT EXISTS identity_sessions (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL,
    organization_id UUID NOT NULL,
    roles TEXT[] NOT NULL,
    secret_hash TEXT NOT NULL,
    last_verified_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_identity_sessions_user ON identity_sessions (user_id);
CREATE INDEX IF NOT EXISTS idx_identity_sessions_org ON identity_sessions (organization_id);
CREATE INDEX IF NOT EXISTS idx_identity_sessions_expires_at ON identity_sessions (expires_at);
