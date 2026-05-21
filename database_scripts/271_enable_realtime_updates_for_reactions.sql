-- Enable REPLICA IDENTITY FULL for course_forum_reactions table
-- This allows Supabase Realtime to broadcast UPDATE events with full row data

-- Set REPLICA IDENTITY to FULL for the reactions table
ALTER TABLE course_forum_reactions REPLICA IDENTITY FULL;

-- Verify the change
SELECT 
    nspname as schema_name,
    relname as table_name,
    CASE relreplident
        WHEN 'd' THEN 'default'
        WHEN 'n' THEN 'nothing'
        WHEN 'f' THEN 'full'
        WHEN 'i' THEN 'index'
    END as replica_identity
FROM pg_class
JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
WHERE 
    nspname = 'public' 
    AND relname = 'course_forum_reactions';

-- Note: After running this script, Supabase Realtime will be able to broadcast
-- UPDATE events with the full row data (both old and new records)
