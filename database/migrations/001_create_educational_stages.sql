CREATE TABLE educational_stages (
    id UUID PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    archived_at TIMESTAMPTZ
);
