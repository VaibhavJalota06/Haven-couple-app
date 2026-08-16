-- ==============================================================================
-- HAVEN: 100% COMPLETE FIX FOR SUPABASE SECURITY ADVISOR
-- Clears ALL 10 Warnings and ALL 6 Info Suggestions
-- Run this in Supabase Dashboard -> SQL Editor (New Query -> Run)
-- ==============================================================================

-- ==============================================================================
-- PART 1: FIX FUNCTION SEARCH PATHS & PERMISSIONS (Resolves all 10 Warnings)
-- ==============================================================================

-- 1.1 generate_invite_code
CREATE OR REPLACE FUNCTION public.generate_invite_code()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT UPPER(SUBSTRING(MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT) FROM 1 FOR 6));
$$;

-- 1.2 handle_updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- 1.3 handle_new_user (Auth Trigger only, revoke from public & anon)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, avatar_url)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        NEW.raw_user_meta_data->>'avatar_url'
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        full_name = COALESCE(EXCLUDED.full_name, public.profiles.full_name);
    RETURN NEW;
END;
$$;

-- 1.4 is_relationship_partner
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

-- 1.5 get_partner_user_id
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

-- 1.6 join_relationship_by_code
CREATE OR REPLACE FUNCTION public.join_relationship_by_code(p_invite_code TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_rel_id UUID;
    v_creator_id UUID;
    v_status relationship_status;
    v_existing_rel_count INT;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Unauthorized: User must be authenticated';
    END IF;

    SELECT COUNT(*) INTO v_existing_rel_count
    FROM public.relationships
    WHERE (user1_id = v_user_id OR user2_id = v_user_id)
      AND status = 'active';

    IF v_existing_rel_count > 0 THEN
        RAISE EXCEPTION 'User is already in an active relationship.';
    END IF;

    SELECT id, user1_id, status INTO v_rel_id, v_creator_id, v_status
    FROM public.relationships
    WHERE UPPER(invite_code) = UPPER(TRIM(p_invite_code))
    LIMIT 1;

    IF v_rel_id IS NULL THEN
        RAISE EXCEPTION 'Invalid invitation code.';
    END IF;

    IF v_creator_id = v_user_id THEN
        RAISE EXCEPTION 'You cannot join your own invite.';
    END IF;

    IF v_status <> 'pending' THEN
        RAISE EXCEPTION 'This invitation is no longer valid.';
    END IF;

    UPDATE public.relationships
    SET user2_id = v_user_id,
        status = 'active',
        updated_at = NOW()
    WHERE id = v_rel_id;

    RETURN jsonb_build_object(
        'success', true,
        'relationship_id', v_rel_id,
        'partner_id', v_creator_id
    );
END;
$$;

-- Revoke public execution on internal trigger functions only
REVOKE ALL ON FUNCTION public.handle_new_user() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.handle_updated_at() FROM PUBLIC, anon;

-- Grant execution on security helper functions so RLS policies can evaluate them
GRANT EXECUTE ON FUNCTION public.get_partner_user_id() TO PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.is_relationship_partner(UUID) TO PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.join_relationship_by_code(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.generate_invite_code() TO PUBLIC, anon, authenticated;


-- ==============================================================================
-- PART 2: ADD RLS POLICIES FOR REMAINING 6 TABLES (Resolves all 6 Info suggestions)
-- ==============================================================================

-- 2.1 message_receipts
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

-- 2.2 message_reactions
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

-- 2.3 calls
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

-- 2.4 call_signals
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

-- 2.5 love_notes (Time-Locked Capsules)
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

-- 2.6 game_sessions
DROP POLICY IF EXISTS "Games accessible to relationship partners" ON public.game_sessions;
CREATE POLICY "Games accessible to relationship partners"
ON public.game_sessions
FOR ALL
USING (public.is_relationship_partner(relationship_id));
