-- Add reply_to_message_id to direct_messages
ALTER TABLE public.direct_messages 
ADD COLUMN IF NOT EXISTS reply_to_message_id UUID REFERENCES public.direct_messages(id);

-- Add is_deleted to direct_messages
ALTER TABLE public.direct_messages 
ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT false;

-- Add is_edited to direct_messages
ALTER TABLE public.direct_messages 
ADD COLUMN IF NOT EXISTS is_edited BOOLEAN DEFAULT false;

-- Create direct_message_reactions table
CREATE TABLE IF NOT EXISTS public.direct_message_reactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    message_id UUID REFERENCES public.direct_messages(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    reaction TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(message_id, user_id, reaction)
);

-- Enable RLS on direct_message_reactions
ALTER TABLE public.direct_message_reactions ENABLE ROW LEVEL SECURITY;

-- RLS Policies for direct_message_reactions

-- View reactions: Users can view reactions on messages they can see
-- (i.e. if they are sender or receiver of the message)
CREATE POLICY "Users can view reactions on their messages"
ON public.direct_message_reactions
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.direct_messages m
        WHERE m.id = direct_message_reactions.message_id
        AND (m.sender_id = auth.uid() OR m.receiver_id = auth.uid())
    )
);

-- Add reactions: Users can add reactions to messages they can see
CREATE POLICY "Users can add reactions to their messages"
ON public.direct_message_reactions
FOR INSERT
WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (
        SELECT 1 FROM public.direct_messages m
        WHERE m.id = direct_message_reactions.message_id
        AND (m.sender_id = auth.uid() OR m.receiver_id = auth.uid())
    )
);

-- Delete reactions: Users can delete their own reactions
CREATE POLICY "Users can delete their own reactions"
ON public.direct_message_reactions
FOR DELETE
USING (auth.uid() = user_id);

-- Add policy for update (if needed, though usually reactions are toggled via insert/delete)
CREATE POLICY "Users can update their own reactions"
ON public.direct_message_reactions
FOR UPDATE
USING (auth.uid() = user_id);
