CREATE TABLE enrollments (
    id UUID PRIMARY KEY,

    student_id UUID NOT NULL
        REFERENCES users (id) ON DELETE RESTRICT,

    course_id UUID NOT NULL
        REFERENCES courses (id) ON DELETE RESTRICT,

    enrolled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE', 'CANCELLED', 'COMPLETED'))
);

CREATE UNIQUE INDEX enrollments_one_active_per_student_course
    ON enrollments (student_id, course_id)
    WHERE status = 'ACTIVE';
