CREATE TABLE learning_items (
    id UUID PRIMARY KEY,

    course_id UUID NOT NULL
        REFERENCES courses (id) ON DELETE RESTRICT,

    lecture_id UUID
        REFERENCES lectures (id) ON DELETE RESTRICT,

    type VARCHAR(20) NOT NULL
        CHECK (
            type IN ('VIDEO', 'FILE', 'ASSIGNMENT', 'EXAM')
        ),

    title VARCHAR(150) NOT NULL,

    description TEXT,

    position INTEGER NOT NULL,

    is_required BOOLEAN NOT NULL DEFAULT TRUE,

    prerequisite_id UUID
        REFERENCES learning_items (id) ON DELETE RESTRICT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
