
CREATE TABLE cancellation_requests (
    id UUID PRIMARY KEY,

    enrollment_id UUID NOT NULL
        REFERENCES enrollments (id) ON DELETE RESTRICT,

    reason TEXT NOT NULL,

    status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
        CHECK (
            status IN ('PENDING', 'APPROVED', 'REJECTED')
        ),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX cancellation_requests_one_active_per_enrollment
    ON cancellation_requests (enrollment_id)
    WHERE status IN ('PENDING', 'APPROVED');
