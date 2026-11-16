CREATE TABLE courses (
    id UUID PRIMARY KEY,

    title VARCHAR(150) NOT NULL,

    description TEXT,

    cover_image_url TEXT,

    price NUMERIC(10, 2) NOT NULL
        CHECK (price >= 0),

    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT'
        CHECK (status IN ('DRAFT', 'PUBLISHED'))
);
