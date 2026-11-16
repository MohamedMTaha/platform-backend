CREATE TABLE exam_answers (
    id UUID PRIMARY KEY,

    attempt_id UUID NOT NULL
        REFERENCES exam_attempts(id)
        ON DELETE RESTRICT,

    question_id UUID NOT NULL
        REFERENCES assessment_questions(id)
        ON DELETE RESTRICT,

    selected_option_id UUID,

    answer_text TEXT,

    is_correct BOOLEAN,

    score NUMERIC(8, 2)
        CHECK (score IS NULL OR score >= 0),

    CONSTRAINT uq_exam_answers_attempt_question
        UNIQUE (attempt_id, question_id),

    CONSTRAINT fk_exam_answers_selected_option
        FOREIGN KEY (selected_option_id, question_id)
        REFERENCES assessment_options(id, question_id)
        ON DELETE RESTRICT
);
