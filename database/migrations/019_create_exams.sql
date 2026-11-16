CREATE TABLE exams (
    learning_item_id UUID PRIMARY KEY
        REFERENCES learning_items(id)
        ON DELETE RESTRICT,

    duration_minutes INTEGER
        CHECK (
            duration_minutes IS NULL
            OR duration_minutes > 0
        ),

    total_marks NUMERIC(8, 2) NOT NULL
        CHECK (total_marks > 0)
);
