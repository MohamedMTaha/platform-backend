
CREATE TABLE assignments (
    learning_item_id UUID PRIMARY KEY
        REFERENCES learning_items(id)
        ON DELETE RESTRICT,

    instructions TEXT NOT NULL
        CHECK (length(trim(instructions)) > 0),

    due_at TIMESTAMPTZ,

    allowed_file_types TEXT[],

    max_submission_size BIGINT
        CHECK (
            max_submission_size IS NULL
            OR max_submission_size > 0
        )
);
