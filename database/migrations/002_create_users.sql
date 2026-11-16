CREATE TABLE users (
    id UUID PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(255) UNIQUE,
    password_hash TEXT NOT NULL,
    role VARCHAR(20) NOT NULL,
    assistant_status VARCHAR(20),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT users_role_check
        CHECK (role IN ('ADMIN', 'ASSISTANT', 'STUDENT')),

    CONSTRAINT users_assistant_status_check
        CHECK (
            (
                role = 'ASSISTANT'
                AND assistant_status IS NOT NULL
                AND assistant_status IN ('ACTIVE', 'DEACTIVATED')
            )
            OR
            (
                role IN ('ADMIN', 'STUDENT')
                AND assistant_status IS NULL
            )
        ),

    CONSTRAINT users_staff_email_check
        CHECK (role = 'STUDENT' OR email IS NOT NULL)
);
