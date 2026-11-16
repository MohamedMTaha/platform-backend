CREATE TABLE storage_cleanup_outbox (
    id UUID PRIMARY KEY,

    storage_provider VARCHAR(50) NOT NULL,

    storage_key TEXT NOT NULL,

    status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
        CHECK (
            status IN (
                'PENDING',
                'PROCESSING',
                'COMPLETED',
                'FAILED'
            )
        ),

    attempt_count INTEGER NOT NULL DEFAULT 0
        CHECK (attempt_count >= 0),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    processed_at TIMESTAMPTZ,

    last_error TEXT
);

CREATE INDEX storage_cleanup_outbox_status_idx
    ON storage_cleanup_outbox (status);
