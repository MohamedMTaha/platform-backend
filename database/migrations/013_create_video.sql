CREATE TABLE videos (
    learning_item_id UUID PRIMARY KEY
        REFERENCES learning_items (id) ON DELETE RESTRICT,

    duration_seconds INTEGER,

    original_storage_key TEXT NOT NULL,

    playlist_storage_key TEXT,

    encryption_key_encrypted BYTEA,

    processing_status VARCHAR(20) NOT NULL DEFAULT 'UPLOAD_PENDING'
        CHECK (
            processing_status IN (
                'UPLOAD_PENDING',
                'UPLOADED',
                'PROCESSING',
                'READY',
                'FAILED'
            )
        ),

    CONSTRAINT videos_duration_check
        CHECK (
            duration_seconds IS NULL
            OR duration_seconds > 0
        ),

    CONSTRAINT videos_ready_data_check
        CHECK (
            (
                processing_status = 'READY'
                AND duration_seconds IS NOT NULL
                AND playlist_storage_key IS NOT NULL
                AND encryption_key_encrypted IS NOT NULL
            )
            OR
            (
                processing_status <> 'READY'
                AND playlist_storage_key IS NULL
                AND encryption_key_encrypted IS NULL
            )
        )
);
