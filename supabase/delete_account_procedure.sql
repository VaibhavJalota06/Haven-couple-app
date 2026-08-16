-- ==============================================================================
-- HAVEN: ACCOUNT DELETION & DEACTIVATION RPC PROCEDURE
-- Paste and run in Supabase Dashboard -> SQL Editor
-- ==============================================================================

-- 1. Complete Self-Service Account Deletion Procedure
CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID := auth.uid();
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Unauthorized: Must be logged in to delete account.';
    END IF;

    -- 1. Clean up relationship spaces
    DELETE FROM public.relationships
    WHERE user1_id = v_user_id OR user2_id = v_user_id;

    -- 2. Clean up posts, comments and sparks
    DELETE FROM public.posts WHERE user_id = v_user_id;
    DELETE FROM public.connection_requests WHERE sender_id = v_user_id OR receiver_id = v_user_id;

    -- 3. Clean up encrypted vault items
    DELETE FROM public.vault_items WHERE owner_id = v_user_id;

    -- 4. Clean up user profile
    DELETE FROM public.profiles WHERE id = v_user_id;

    -- 5. Purge auth credentials from Supabase Auth
    DELETE FROM auth.users WHERE id = v_user_id;

    RETURN jsonb_build_object(
        'success', true, 
        'message', 'User account and all associated couple data permanently erased.'
    );
END;
$$;

REVOKE ALL ON FUNCTION public.delete_user_account() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.delete_user_account() TO authenticated;


-- 2. Account Deactivation (Temporary Pause / Hidden Mode)
CREATE OR REPLACE FUNCTION public.deactivate_user_account()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID := auth.uid();
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Unauthorized: Must be logged in to deactivate account.';
    END IF;

    UPDATE public.profiles
    SET is_online = false,
        mood = 'Deactivated (Away)',
        mood_emoji = '🌙',
        updated_at = NOW()
    WHERE id = v_user_id;

    RETURN jsonb_build_object(
        'success', true, 
        'message', 'Account temporarily deactivated. Log back in any time to resume.'
    );
END;
$$;

REVOKE ALL ON FUNCTION public.deactivate_user_account() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.deactivate_user_account() TO authenticated;
