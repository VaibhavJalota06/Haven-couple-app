-- ==============================================================================
-- HAVEN: STORED PROCEDURES, TRIGGERS & REALTIME SUBSCRIPTIONS
-- ==============================================================================

-- 1. Automatic Profile Creation on User Signup
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
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 2. Invite Code Generator (6 uppercase alphanumeric characters)
CREATE OR REPLACE FUNCTION public.generate_invite_code()
RETURNS TEXT
LANGUAGE sql
AS $$
    SELECT UPPER(SUBSTRING(MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT) FROM 1 FOR 6));
$$;

-- 3. Stored Procedure: Join Relationship by Invite Code
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

    -- Check if current user is already in an active relationship
    SELECT COUNT(*) INTO v_existing_rel_count
    FROM public.relationships
    WHERE (user1_id = v_user_id OR user2_id = v_user_id)
      AND status = 'active';

    IF v_existing_rel_count > 0 THEN
        RAISE EXCEPTION 'User is already in an active relationship. An account can only belong to one couple.';
    END IF;

    -- Look up relationship with the given invite code
    SELECT id, user1_id, status INTO v_rel_id, v_creator_id, v_status
    FROM public.relationships
    WHERE UPPER(invite_code) = UPPER(TRIM(p_invite_code))
    LIMIT 1;

    IF v_rel_id IS NULL THEN
        RAISE EXCEPTION 'Invalid invitation code. Please check with your partner.';
    END IF;

    IF v_creator_id = v_user_id THEN
        RAISE EXCEPTION 'You cannot join your own relationship invite.';
    END IF;

    IF v_status <> 'pending' THEN
        RAISE EXCEPTION 'This invitation code is no longer valid or has already been accepted.';
    END IF;

    -- Activate relationship and assign user2
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

-- 4. Automatic Update of updated_at Timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER update_profiles_timestamp BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER update_relationships_timestamp BEFORE UPDATE ON public.relationships FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER update_vault_timestamp BEFORE UPDATE ON public.vault_items FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER update_memories_timestamp BEFORE UPDATE ON public.memories FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER update_date_plans_timestamp BEFORE UPDATE ON public.date_plans FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 5. Add Tables to Supabase Realtime Publication
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.message_receipts;
ALTER PUBLICATION supabase_realtime ADD TABLE public.message_reactions;
ALTER PUBLICATION supabase_realtime ADD TABLE public.calls;
ALTER PUBLICATION supabase_realtime ADD TABLE public.call_signals;
ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;
ALTER PUBLICATION supabase_realtime ADD TABLE public.relationships;
ALTER PUBLICATION supabase_realtime ADD TABLE public.game_sessions;
