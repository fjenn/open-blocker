-- Open Blocker anonymous ping tracking
-- Tracks only first successful block event per install

CREATE TABLE IF NOT EXISTS pings (
    id bigserial PRIMARY KEY,
    install_id uuid NOT NULL,
    event text NOT NULL,
    app_version text,
    created_at timestamptz DEFAULT now(),
    UNIQUE(install_id, event)
);

-- Enable RLS
ALTER TABLE pings ENABLE ROW LEVEL SECURITY;

-- Insert-only policy for anonymous users
CREATE POLICY "Allow anonymous inserts"
    ON pings
    FOR INSERT
    TO anon
    WITH CHECK (true);

-- No select for anonymous users (data is private)
-- Authenticated users with proper role can query for exports
