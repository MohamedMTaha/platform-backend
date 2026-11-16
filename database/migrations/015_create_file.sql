CREATE TABLE files (
    learning_item_id UUID PRIMARY KEY
        REFERENCES learning_items (id) ON DELETE RESTRICT,

    storage_key TEXT NOT NULL UNIQUE,
    original_filename TEXT NOT NULL,
    mime_type VARCHAR(255) NOT NULL,
    size_bytes BIGINT NOT NULL CHECK (size_bytes > 0)
);
