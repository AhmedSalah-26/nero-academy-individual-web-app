-- Direct Messages table for 1-on-1 chat between instructors and students
CREATE TABLE IF NOT EXISTS direct_messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  receiver_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  message_text TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_dm_sender ON direct_messages (sender_id, created_at);
CREATE INDEX IF NOT EXISTS idx_dm_receiver ON direct_messages (receiver_id, created_at);
CREATE INDEX IF NOT EXISTS idx_dm_participants ON direct_messages (
  LEAST(sender_id, receiver_id),
  GREATEST(sender_id, receiver_id),
  created_at
);

-- Row Level Security
ALTER TABLE direct_messages ENABLE ROW LEVEL SECURITY;

-- Users can only read messages where they are sender or receiver
CREATE POLICY "Users can read own DMs"
  ON direct_messages FOR SELECT
  USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

-- Users can only send messages as themselves
CREATE POLICY "Users can send DMs"
  ON direct_messages FOR INSERT
  WITH CHECK (auth.uid() = sender_id);

-- Users can update their own received messages (for marking as read)
CREATE POLICY "Users can mark DMs as read"
  ON direct_messages FOR UPDATE
  USING (auth.uid() = receiver_id)
  WITH CHECK (auth.uid() = receiver_id);

-- Enable realtime for this table
ALTER PUBLICATION supabase_realtime ADD TABLE direct_messages;
