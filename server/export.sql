-- Export anonymous ping data for analysis
-- Run this query as an authenticated user with table access

COPY (
    SELECT 
        DATE(created_at) as date,
        event,
        app_version,
        COUNT(DISTINCT install_id) as unique_installs,
        COUNT(*) as total_pings
    FROM pings
    WHERE created_at >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY DATE(created_at), event, app_version
    ORDER BY date DESC, event, app_version
) TO STDOUT WITH CSV HEADER;

-- To save to file:
-- \copy (SELECT ...) TO 'pings_export_2026-10-12.csv' WITH CSV HEADER
