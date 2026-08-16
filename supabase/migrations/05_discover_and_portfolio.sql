-- ==============================================================================
-- HAVEN: DISCOVER & PERSONAL PORTFOLIO SCHEMA (INSTAGRAM-STYLE EXPLORE)
-- ==============================================================================

-- 1. Posts Table (Portfolio Photos & Video Reels)
CREATE TYPE post_media_type AS ENUM ('photo', 'reel');

CREATE TABLE IF NOT EXISTS public.posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    media_url TEXT NOT NULL,
    thumbnail_url TEXT,
    media_type post_media_type NOT NULL DEFAULT 'photo',
    caption TEXT,
    location_name TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_posts_user ON public.posts(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_explore ON public.posts(created_at DESC);

-- 2. Connection Requests Table (Mutual Couple Handshake)
CREATE TYPE connection_request_status AS ENUM ('pending', 'accepted', 'declined', 'cancelled');

CREATE TABLE IF NOT EXISTS public.connection_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status connection_request_status NOT NULL DEFAULT 'pending',
    message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_pending_request UNIQUE (sender_id, receiver_id),
    CONSTRAINT different_users CHECK (sender_id <> receiver_id)
);

CREATE INDEX IF NOT EXISTS idx_requests_receiver ON public.connection_requests(receiver_id, status);
CREATE INDEX IF NOT EXISTS idx_requests_sender ON public.connection_requests(sender_id, status);

-- 3. Stored Procedure: Accept Connection Request and Create Couple Relationship
CREATE OR REPLACE FUNCTION public.accept_connection_request(p_request_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_receiver_id UUID := auth.uid();
    v_sender_id UUID;
    v_status connection_request_status;
    v_rel_id UUID;
    v_existing_rel INT;
BEGIN
    IF v_receiver_id IS NULL THEN
        RAISE EXCEPTION 'Unauthorized: User must be authenticated';
    END IF;

    -- Fetch request
    SELECT sender_id, status INTO v_sender_id, v_status
    FROM public.connection_requests
    WHERE id = p_request_id AND receiver_id = v_receiver_id;

    IF v_sender_id IS NULL THEN
        RAISE EXCEPTION 'Connection request not found or not addressed to you.';
    END IF;

    IF v_status <> 'pending' THEN
        RAISE EXCEPTION 'This request is no longer pending.';
    END IF;

    -- Check if either user is already in an active relationship
    SELECT COUNT(*) INTO v_existing_rel
    FROM public.relationships
    WHERE (user1_id IN (v_sender_id, v_receiver_id) OR user2_id IN (v_sender_id, v_receiver_id))
      AND status = 'active';

    IF v_existing_rel > 0 THEN
        RAISE EXCEPTION 'One of the users is already in an active relationship.';
    END IF;

    -- Update request status
    UPDATE public.connection_requests
    SET status = 'accepted', updated_at = NOW()
    WHERE id = p_request_id;

    -- Create new active relationship
    INSERT INTO public.relationships (user1_id, user2_id, invite_code, status, anniversary_date, custom_nickname)
    VALUES (
        v_sender_id,
        v_receiver_id,
        public.generate_invite_code(),
        'active',
        CURRENT_DATE,
        'Us'
    )
    RETURNING id INTO v_rel_id;

    RETURN jsonb_build_object(
        'success', true,
        'relationship_id', v_rel_id,
        'partner_id', v_sender_id
    );
END;
$$;

-- ==============================================================================
-- 4. ROW LEVEL SECURITY (RLS) POLICIES FOR DISCOVER & PORTFOLIO
-- ==============================================================================
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.connection_requests ENABLE ROW LEVEL SECURITY;

-- Posts: Publicly viewable by any authenticated user for discovery
CREATE POLICY "Posts viewable by all authenticated users"
ON public.posts FOR SELECT
USING (auth.role() = 'authenticated');

CREATE POLICY "Users can create their own posts"
ON public.posts FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own posts"
ON public.posts FOR DELETE
USING (auth.uid() = user_id);

-- Connection Requests: Sender & Receiver access only
CREATE POLICY "Requests viewable by sender and receiver"
ON public.connection_requests FOR SELECT
USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY "Users can send connection requests"
ON public.connection_requests FOR INSERT
WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can update their received or sent requests"
ON public.connection_requests FOR UPDATE
USING (auth.uid() = receiver_id OR auth.uid() = sender_id);
