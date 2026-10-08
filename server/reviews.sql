-- Open Blocker user reviews table
-- Collects optional feedback after 3rd block

CREATE TABLE IF NOT EXISTS reviews (
    id bigserial PRIMARY KEY,
    install_id uuid NOT NULL,
    review text NOT NULL,
    email text,
    app_version text,
    platform text,
    created_at timestamptz DEFAULT now(),
    UNIQUE(install_id)
);

-- Enable RLS
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- Insert-only policy for anonymous users
CREATE POLICY "Allow anonymous review inserts"
    ON reviews
    FOR INSERT
    TO anon
    WITH CHECK (true);

-- No select for anonymous users (data is private)
-- Authenticated users with proper role can query for analysis

-- Note on email:
-- Email is optional. If provided, used only to follow up on feedback.
-- Users can request deletion by emailing support.
