-- Add policies to allow admins to delete/update messages in groups and direct chats
-- (Unified schema uses the 'messages' table for both)
-- ==============================================================================

-- Allow admins to UPDATE any message (for soft deletion: is_deleted = true)
-- Note: Soft deletion is all we need as per the app logic.
CREATE POLICY "Admins can update any message"
ON messages FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.id = auth.uid() AND p.role = 'admin'
    )
);
