-- ==============================================================================
-- HAVEN: COMPLETE RLS SECURITY POLICIES (Resolves Security Advisor Warnings)
-- Run this in Supabase Dashboard -> SQL Editor (New Query -> Run)
-- ==============================================================================

-- 1. MESSAGE RECEIPTS POLICIES
DROP POLICY IF EXISTS "Receipts access for relationship partners" ON public.message_receipts;
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

-- 2. MESSAGE REACTIONS POLICIES
DROP POLICY IF EXISTS "Reactions access for relationship partners" ON public.message_reactions;
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

-- 3. CALLS POLICIES
DROP POLICY IF EXISTS "Calls viewable by participants" ON public.calls;
CREATE POLICY "Calls viewable by participants"
ON public.calls
FOR SELECT
USING (public.is_relationship_partner(relationship_id));

DROP POLICY IF EXISTS "Partners can initiate calls" ON public.calls;
CREATE POLICY "Partners can initiate calls"
ON public.calls
FOR INSERT
WITH CHECK (
    public.is_relationship_partner(relationship_id)
    AND auth.uid() = caller_id
);

DROP POLICY IF EXISTS "Partners can update call status" ON public.calls;
CREATE POLICY "Partners can update call status"
ON public.calls
FOR UPDATE
USING (public.is_relationship_partner(relationship_id));

-- 4. CALL SIGNALS POLICIES
DROP POLICY IF EXISTS "Signals viewable by call participants" ON public.call_signals;
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

-- 5. LOVE NOTES (Time-Locked Capsules)
DROP POLICY IF EXISTS "Love notes viewable when unlocked" ON public.love_notes;
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

DROP POLICY IF EXISTS "Senders can create love notes" ON public.love_notes;
CREATE POLICY "Senders can create love notes"
ON public.love_notes
FOR INSERT
WITH CHECK (
    public.is_relationship_partner(relationship_id)
    AND auth.uid() = sender_id
);

-- 6. GAME SESSIONS POLICIES
DROP POLICY IF EXISTS "Games accessible to relationship partners" ON public.game_sessions;
CREATE POLICY "Games accessible to relationship partners"
ON public.game_sessions
FOR ALL
USING (public.is_relationship_partner(relationship_id));
