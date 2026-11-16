CREATE TABLE assignment_submissions (
    id UUID PRIMARY KEY,

    assignment_id UUID NOT NULL
        REFERENCES assignments(learning_item_id)
        ON DELETE RESTRICT,

    enrollment_id UUID NOT NULL
        REFERENCES enrollments(id)
        ON DELETE RESTRICT,

    submission_key TEXT NOT NULL,

    submitted_at TIMESTAMPTZ NOT NULL,

    status VARCHAR(20) NOT NULL DEFAULT 'SUBMITTED'
        CHECK (
            status IN (
                'SUBMITTED',
                'UNDER_REVIEW',
                'ACCEPTED',
                'REJECTED'
            )
        ),

    rejection_reason TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_assignment_submissions_assignment_enrollment
        UNIQUE (assignment_id, enrollment_id),

    CONSTRAINT chk_assignment_submissions_rejection_reason
        CHECK (
            status <> 'REJECTED'
            OR (
                rejection_reason IS NOT NULL
                AND length(trim(rejection_reason)) > 0
            )
        )
);
