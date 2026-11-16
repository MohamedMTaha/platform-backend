CREATE TABLE assistant_audit_logs (
    id UUID PRIMARY KEY,

    assistant_id UUID NOT NULL
        REFERENCES users (id) ON DELETE RESTRICT,

    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID NOT NULL,

    reason TEXT,

    before_data JSONB,
    after_data JSONB,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
