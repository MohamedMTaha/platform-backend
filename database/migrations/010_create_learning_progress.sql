CREATE TABLE learning_progress (
    id UUID PRIMARY KEY,

    enrollment_id UUID NOT NULL
        REFERENCES enrollments (id) ON DELETE RESTRICT,

    learning_item_id UUID NOT NULL
        REFERENCES learning_items (id) ON DELETE RESTRICT,

    status VARCHAR(20) NOT NULL DEFAULT 'NOT_STARTED'
        CHECK (status IN ('NOT_STARTED', 'IN_PROGRESS', 'COMPLETED')),

    completed_at TIMESTAMPTZ,

    CONSTRAINT learning_progress_enrollment_item_unique
        UNIQUE (enrollment_id, learning_item_id),

    CONSTRAINT learning_progress_completed_at_check
        CHECK (
            (status = 'COMPLETED' AND completed_at IS NOT NULL)
            OR
            (status IN ('NOT_STARTED', 'IN_PROGRESS') AND completed_at IS NULL)
        )
);
