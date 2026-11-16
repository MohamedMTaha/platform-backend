CREATE TABLE assessment_options (
    id UUID PRIMARY KEY,

    question_id UUID NOT NULL
        REFERENCES assessment_questions(id)
        ON DELETE RESTRICT,

    option_text TEXT NOT NULL
        CHECK (length(trim(option_text)) > 0),

    is_correct BOOLEAN NOT NULL,

    position INTEGER NOT NULL
        CHECK (position > 0),

    CONSTRAINT uq_assessment_options_id_question
        UNIQUE (id, question_id),

    CONSTRAINT uq_assessment_options_position
        UNIQUE (question_id, position)
);
