CREATE TABLE course_stages (
    course_id UUID NOT NULL
        REFERENCES courses (id) ON DELETE RESTRICT,

    educational_stage_id UUID NOT NULL
        REFERENCES educational_stages (id) ON DELETE RESTRICT,

    PRIMARY KEY (course_id, educational_stage_id)
);
