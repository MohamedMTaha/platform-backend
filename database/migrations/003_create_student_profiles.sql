CREATE TABLE student_profiles (
    user_id UUID PRIMARY KEY
        REFERENCES users (id) ON DELETE RESTRICT,

    national_id VARCHAR(14) NOT NULL UNIQUE,
    date_of_birth DATE NOT NULL,
    address TEXT NOT NULL,
    parent_phone VARCHAR(20) NOT NULL,

    educational_stage_id UUID NOT NULL
        REFERENCES educational_stages (id) ON DELETE RESTRICT,

    id_card_image TEXT NOT NULL,

    status VARCHAR(20) NOT NULL
        CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'BANNED'))
);
