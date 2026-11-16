CREATE TABLE exam_attempts (
    id UUID PRIMARY KEY,

    enrollment_id UUID NOT NULL
        REFERENCES enrollments(id)
        ON DELETE RESTRICT,

    exam_id UUID NOT NULL
        REFERENCES exams(learning_item_id)
        ON DELETE RESTRICT,

    attempt_number INTEGER NOT NULL
        CHECK (attempt_number > 0),

    started_at TIMESTAMPTZ NOT NULL,

    submitted_at TIMESTAMPTZ,

    score NUMERIC(8, 2)
        CHECK (score IS NULL OR score >= 0),

    status VARCHAR(20) NOT NULL
        CHECK (
            status IN (
                'IN_PROGRESS',
                'SUBMITTED',
                'PENDING_GRADING',
                'GRADED',
                'INVALIDATED'
            )
        ),

    reset_idempotency_key TEXT UNIQUE,

    CONSTRAINT uq_exam_attempts_number
        UNIQUE (enrollment_id, exam_id, attempt_number)
);
