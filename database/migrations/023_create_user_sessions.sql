CREATE TABLE user_sessions (
    id UUID PRIMARY KEY,

    user_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE RESTRICT,

    refresh_token_hash VARCHAR(64) NOT NULL UNIQUE,

    expires_at TIMESTAMPTZ NOT NULL,

    revoked_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    last_used_at TIMESTAMPTZ,

    CONSTRAINT user_sessions_refresh_token_hash_format_check
        CHECK (refresh_token_hash ~ '^[0-9a-f]{64}$'),

    CONSTRAINT user_sessions_expiry_check
        CHECK (expires_at > created_at)
);

CREATE UNIQUE INDEX uq_user_sessions_active_user
    ON user_sessions(user_id)
    WHERE revoked_at IS NULL;
