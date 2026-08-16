-- ==============================================================================
-- HAVEN: AIRTIGHT ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

-- Enable Row Level Security on ALL tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.relationships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.message_receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.message_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calls ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.call_signals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vault_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.memories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.date_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bucket_list ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shared_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.love_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.game_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;

-- ==============================================================================
-- SECURITY HELPER FUNCTIONS
-- ==============================================================================

-- Helper to check if the authenticated user is a partner in a given relationship
CREATE OR REPLACE FUNCTION public.is_relationship_partner(rel_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.relationships
        WHERE id = rel_id
        AND (user1_id = auth.uid() OR user2_id = auth.uid())
    );
$$;

-- Helper to fetch the current user's partner ID
CREATE OR REPLACE FUNCTION public.get_partner_user_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT 
        CASE 
            WHEN user1_id = auth.uid() THEN user2_id
            WHEN user2_id = auth.uid() THEN user1_id
            ELSE NULL
        END
    FROM public.relationships
    WHERE (user1_id = auth.uid() OR user2_id = auth.uid())
      AND status = 'active'
    LIMIT 1;
$$;

-- ==============================================================================
-- 1. PROFILES POLICIES
-- ==============================================================================
-- Users can view their own profile and their connected partner's profile
CREATE POLICY "Profiles viewable by self and partner"
ON public.profiles
FOR SELECT
USING (
    auth.uid() = id
    OR
    id = public.get_partner_user_id()
    OR
    EXISTS (
        -- Allow partner to see creator profile when accepting invite
        SELECT 1 FROM public.relationships 
        WHERE user1_id = profiles.id 
          AND status = 'pending'
    )
);

-- Users can only insert/update their own profile
CREATE POLICY "Users can insert their own profile"
ON public.profiles
FOR INSERT
WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
ON public.profiles
FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- ==============================================================================
-- 2. RELATIONSHIPS POLICIES
-- ==============================================================================
-- Users can see relationships they are part of, or pending invite codes
CREATE POLICY "Relationships viewable by participants"
ON public.relationships
FOR SELECT
USING (
    auth.uid() = user1_id 
    OR auth.uid() = user2_id 
    OR (status = 'pending' AND invite_code IS NOT NULL)
);

CREATE POLICY "Authenticated users can create relationship"
ON public.relationships
FOR INSERT
WITH CHECK (auth.uid() = user1_id);

CREATE POLICY "Participants can update their relationship"
ON public.relationships
FOR UPDATE
USING (auth.uid() = user1_id OR auth.uid() = user2_id)
WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);

-- ==============================================================================
-- 3. MESSAGES POLICIES
-- ==============================================================================
CREATE POLICY "Messages viewable only by relationship partners"
ON public.messages
FOR SELECT
USING (public.is_relationship_partner(relationship_id));

CREATE POLICY "Partners can send messages"
ON public.messages
FOR INSERT
WITH CHECK (
    public.is_relationship_partner(relationship_id)
    AND auth.uid() = sender_id
);

CREATE POLICY "Senders can edit or soft-delete messages"
ON public.messages
FOR UPDATE
USING (
    public.is_relationship_partner(relationship_id)
    AND auth.uid() = sender_id
);

-- ==============================================================================
-- 4. MESSAGE RECEIPTS & REACTIONS
-- ==============================================================================
CREATE POLICY "Receipts access for relationship partners"
ON public.message_receipts
FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM public.messages m
        WHERE m.id = message_receipts.message_id
        AND public.is_relationship_partner(m.relationship_id)
    )
);

CREATE POLICY "Reactions access for relationship partners"
ON public.message_reactions
FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM public.messages m
        WHERE m.id = message_reactions.message_id
        AND public.is_relationship_partner(m.relationship_id)
    )
);

-- ==============================================================================
-- 5. CALLS & SIGNALING POLICIES
-- ==============================================================================
CREATE POLICY "Calls viewable by participants"
ON public.calls
FOR SELECT
USING (public.is_relationship_partner(relationship_id));

CREATE POLICY "Partners can initiate calls"
ON public.calls
FOR INSERT
WITH CHECK (
    public.is_relationship_partner(relationship_id)
    AND auth.uid() = caller_id
);

CREATE POLICY "Partners can update call status"
ON public.calls
FOR UPDATE
USING (public.is_relationship_partner(relationship_id));

CREATE POLICY "Signals viewable by call participants"
ON public.call_signals
FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM public.calls c
        WHERE c.id = call_signals.call_id
        AND public.is_relationship_partner(c.relationship_id)
    )
);

-- ==============================================================================
-- 6. PRIVATE VAULT POLICIES
-- ==============================================================================
CREATE POLICY "Vault items viewable only by relationship partners"
ON public.vault_items
FOR SELECT
USING (public.is_relationship_partner(relationship_id));

CREATE POLICY "Partners can insert vault items"
ON public.vault_items
FOR INSERT
WITH CHECK (
    public.is_relationship_partner(relationship_id)
    AND auth.uid() = owner_id
);

CREATE POLICY "Owners can update or delete vault items"
ON public.vault_items
FOR DELETE
USING (
    public.is_relationship_partner(relationship_id)
    AND auth.uid() = owner_id
);

-- ==============================================================================
-- 7. MEMORIES POLICIES
-- ==============================================================================
CREATE POLICY "Memories accessible to relationship partners"
ON public.memories
FOR ALL
USING (public.is_relationship_partner(relationship_id));

-- ==============================================================================
-- 8. PLANS (DATE PLANS, BUCKET LIST, SHARED GOALS)
-- ==============================================================================
CREATE POLICY "Date plans accessible to relationship partners"
ON public.date_plans
FOR ALL
USING (public.is_relationship_partner(relationship_id));

CREATE POLICY "Bucket list accessible to relationship partners"
ON public.bucket_list
FOR ALL
USING (public.is_relationship_partner(relationship_id));

CREATE POLICY "Shared goals accessible to relationship partners"
ON public.shared_goals
FOR ALL
USING (public.is_relationship_partner(relationship_id));

-- ==============================================================================
-- 9. LOVE NOTES (Time-locked visibility)
-- ==============================================================================
CREATE POLICY "Love notes viewable when unlocked"
ON public.love_notes
FOR SELECT
USING (
    public.is_relationship_partner(relationship_id)
    AND (
        auth.uid() = sender_id 
        OR unlock_at <= NOW()
    )
);

CREATE POLICY "Senders can create love notes"
ON public.love_notes
FOR INSERT
WITH CHECK (
    public.is_relationship_partner(relationship_id)
    AND auth.uid() = sender_id
);

-- ==============================================================================
-- 10. GAME SESSIONS POLICIES
-- ==============================================================================
CREATE POLICY "Games accessible to relationship partners"
ON public.game_sessions
FOR ALL
USING (public.is_relationship_partner(relationship_id));

-- ==============================================================================
-- 11. DEVICES & SESSIONS POLICIES
-- ==============================================================================
CREATE POLICY "Users can manage only their own devices"
ON public.devices
FOR ALL
USING (auth.uid() = user_id);
