CREATE TABLE assessment_questions (
    id UUID PRIMARY KEY,

    learning_item_id UUID NOT NULL
        REFERENCES learning_items(id)
        ON DELETE RESTRICT,

    type VARCHAR(30) NOT NULL
        CHECK (type IN ('MULTIPLE_CHOICE', 'TRUE_FALSE', 'ESSAY')),

    question_text TEXT NOT NULL
        CHECK (length(trim(question_text)) > 0),

    points NUMERIC(8, 2)
        CHECK (points IS NULL OR points >= 0),

    position INTEGER NOT NULL
        CHECK (position > 0),

    CONSTRAINT uq_assessment_questions_id_learning_item
        UNIQUE (id, learning_item_id),

    CONSTRAINT uq_assessment_questions_position
        UNIQUE (learning_item_id, position)
);
