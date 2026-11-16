CREATE TABLE lectures (
    id UUID PRIMARY KEY,

    course_id UUID NOT NULL
        REFERENCES courses (id) ON DELETE RESTRICT,

    title VARCHAR(150) NOT NULL,

    position INTEGER NOT NULL,

    CONSTRAINT lectures_course_position_unique
        UNIQUE (course_id, position)
);
