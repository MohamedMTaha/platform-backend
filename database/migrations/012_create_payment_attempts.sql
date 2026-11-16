CREATE TABLE payment_attempts (
    id UUID PRIMARY KEY,

    student_id UUID NOT NULL
        REFERENCES users (id) ON DELETE RESTRICT,

    course_id UUID NOT NULL
        REFERENCES courses (id) ON DELETE RESTRICT,

    enrollment_id UUID
        REFERENCES enrollments (id) ON DELETE RESTRICT,

    amount NUMERIC(10, 2) NOT NULL
        CHECK (amount >= 0),

    provider VARCHAR(50) NOT NULL,
    provider_reference TEXT,

    status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
        CHECK (status IN ('PENDING', 'SUCCEEDED', 'FAILED')),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT payment_attempts_provider_reference_unique
        UNIQUE (provider, provider_reference)
);

-- A student can have only one unresolved payment attempt for a course.
CREATE UNIQUE INDEX payment_attempts_one_pending_per_student_course
    ON payment_attempts (student_id, course_id)
    WHERE status = 'PENDING';
