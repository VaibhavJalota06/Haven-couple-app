-- ==============================================================================
-- HAVEN: CONSOLIDATED PRODUCTION MASTER SCHEMA FOR SUPABASE
-- Run this script in your Supabase Dashboard -> SQL Editor (New Query -> Run)
-- ==============================================================================

-- 1. Enable Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- 2. CORE ENUMS & TYPES
-- ==============================================================================
DO $$ BEGIN
    CREATE TYPE relationship_status AS ENUM ('pending', 'active', 'paused', 'disconnected');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE message_type AS ENUM ('text', 'image', 'video', 'voice', 'document', 'location', 'game_invite');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE receipt_status AS ENUM ('sent', 'delivered', 'read');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE call_type AS ENUM ('audio', 'video');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE call_status AS ENUM ('initiating', 'ringing', 'accepted', 'rejected', 'ended', 'missed');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE signal_type AS ENUM ('offer', 'answer', 'ice_candidate', 'bye');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE vault_item_type AS ENUM ('photo', 'video', 'note', 'voice_memo', 'document');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE post_media_type AS ENUM ('photo', 'reel');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE connection_request_status AS ENUM ('pending', 'accepted', 'declined', 'cancelled');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- ==============================================================================
-- 3. CORE TABLES
-- ==============================================================================

-- 3.1 Profiles Table
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT NOT NULL,
    nickname TEXT,
    avatar_url TEXT,
    cover_url TEXT,
    bio TEXT,
    work TEXT,
    education TEXT,
    current_city TEXT,
    hometown TEXT,
    relationship_status TEXT,
    website TEXT,
    hobbies TEXT[] DEFAULT '{}',
    mood TEXT DEFAULT 'loved',
    mood_emoji TEXT DEFAULT '🥰',
    mood_updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_seen TIMESTAMPTZ DEFAULT NOW(),
    is_online BOOLEAN DEFAULT false,
    phone TEXT UNIQUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_phone ON public.profiles(phone);

-- 3.2 Relationships Table
CREATE TABLE IF NOT EXISTS public.relationships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user1_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    user2_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    invite_code VARCHAR(12) UNIQUE NOT NULL,
    status relationship_status NOT NULL DEFAULT 'pending',
    anniversary_date DATE,
    custom_nickname TEXT,
    theme_preference TEXT DEFAULT 'obsidian_gold',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_couple_pair UNIQUE (user1_id, user2_id),
    CONSTRAINT different_partners CHECK (user1_id <> user2_id)
);

CREATE INDEX IF NOT EXISTS idx_relationships_user1 ON public.relationships(user1_id);
CREATE INDEX IF NOT EXISTS idx_relationships_user2 ON public.relationships(user2_id);
CREATE INDEX IF NOT EXISTS idx_relationships_invite_code ON public.relationships(invite_code);
CREATE UNIQUE INDEX IF NOT EXISTS idx_single_active_rel_user1 ON public.relationships(user1_id) WHERE status = 'active';
CREATE UNIQUE INDEX IF NOT EXISTS idx_single_active_rel_user2 ON public.relationships(user2_id) WHERE status = 'active';

-- 3.3 Messages Table
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    relationship_id UUID NOT NULL REFERENCES public.relationships(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT,
    media_url TEXT,
    media_thumbnail_url TEXT,
    media_type message_type NOT NULL DEFAULT 'text',
    media_duration_seconds INTEGER,
    reply_to_id UUID REFERENCES public.messages(id) ON DELETE SET NULL,
    is_view_once BOOLEAN DEFAULT false,
    viewed_at TIMESTAMPTZ,
    is_pinned BOOLEAN DEFAULT false,
    is_starred BOOLEAN DEFAULT false,
    is_deleted BOOLEAN DEFAULT false,
    is_edited BOOLEAN DEFAULT false,
    edited_at TIMESTAMPTZ,
    scheduled_for TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_messages_relationship_time ON public.messages(relationship_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_pinned ON public.messages(relationship_id) WHERE is_pinned = true;

-- 3.4 Message Receipts
CREATE TABLE IF NOT EXISTS public.message_receipts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status receipt_status NOT NULL DEFAULT 'sent',
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_message_user_receipt UNIQUE (message_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_receipts_message ON public.message_receipts(message_id);

-- 3.5 Message Reactions
CREATE TABLE IF NOT EXISTS public.message_reactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    reaction TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_message_user_reaction UNIQUE (message_id, user_id)
);

-- 3.6 Calls & WebRTC Signaling
CREATE TABLE IF NOT EXISTS public.calls (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    relationship_id UUID NOT NULL REFERENCES public.relationships(id) ON DELETE CASCADE,
    caller_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    call_type call_type NOT NULL DEFAULT 'video',
    status call_status NOT NULL DEFAULT 'initiating',
    started_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    duration_seconds INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_calls_relationship ON public.calls(relationship_id, created_at DESC);

CREATE TABLE IF NOT EXISTS public.call_signals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    call_id UUID NOT NULL REFERENCES public.calls(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    signal_type signal_type NOT NULL,
    payload JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_signals_call ON public.call_signals(call_id, created_at ASC);

-- 3.7 Vault Items (E2EE Encrypted)
CREATE TABLE IF NOT EXISTS public.vault_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    relationship_id UUID NOT NULL REFERENCES public.relationships(id) ON DELETE CASCADE,
    owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    item_type vault_item_type NOT NULL,
    title TEXT NOT NULL,
    encrypted_payload TEXT NOT NULL,
    iv TEXT NOT NULL,
    auth_tag TEXT NOT NULL,
    media_url TEXT,
    file_size_bytes BIGINT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_vault_relationship ON public.vault_items(relationship_id, created_at DESC);

-- 3.8 Memories Table
CREATE TABLE IF NOT EXISTS public.memories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    relationship_id UUID NOT NULL REFERENCES public.relationships(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    memory_date DATE NOT NULL,
    location_name TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    media_urls TEXT[] DEFAULT '{}',
    audio_memo_url TEXT,
    category TEXT DEFAULT 'general',
    is_favorite BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_memories_timeline ON public.memories(relationship_id, memory_date DESC);

-- 3.9 Date Plans Table
CREATE TABLE IF NOT EXISTS public.date_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    relationship_id UUID NOT NULL REFERENCES public.relationships(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    category TEXT DEFAULT 'dinner',
    scheduled_for TIMESTAMPTZ NOT NULL,
    location_name TEXT,
    budget NUMERIC(10, 2) DEFAULT 0.00,
    currency VARCHAR(3) DEFAULT 'USD',
    checklist JSONB DEFAULT '[]'::JSONB,
    notes TEXT,
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_date_plans ON public.date_plans(relationship_id, scheduled_for ASC);

-- 3.10 Bucket List Table
CREATE TABLE IF NOT EXISTS public.bucket_list (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    relationship_id UUID NOT NULL REFERENCES public.relationships(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    category TEXT DEFAULT 'travel',
    target_date DATE,
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMPTZ,
    photos TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bucket_list ON public.bucket_list(relationship_id, created_at DESC);

-- 3.11 Shared Goals Table
CREATE TABLE IF NOT EXISTS public.shared_goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    relationship_id UUID NOT NULL REFERENCES public.relationships(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    category TEXT DEFAULT 'finance',
    target_amount NUMERIC(12, 2) NOT NULL,
    current_amount NUMERIC(12, 2) DEFAULT 0.00,
    currency VARCHAR(3) DEFAULT 'USD',
    target_date DATE,
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_shared_goals ON public.shared_goals(relationship_id);

-- 3.12 Love Notes (Time-Locked Capsules)
CREATE TABLE IF NOT EXISTS public.love_notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    relationship_id UUID NOT NULL REFERENCES public.relationships(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    unlock_at TIMESTAMPTZ NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3.13 Game Sessions Table
CREATE TABLE IF NOT EXISTS public.game_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    relationship_id UUID NOT NULL REFERENCES public.relationships(id) ON DELETE CASCADE,
    game_type TEXT NOT NULL,
    current_turn_user_id UUID REFERENCES public.profiles(id),
    state JSONB NOT NULL DEFAULT '{}'::JSONB,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3.14 Discover Posts Table
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

-- 3.15 Connection Requests Table (Sparks)
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

-- ==============================================================================
-- 4. FUNCTIONS, STORED PROCEDURES & TRIGGERS
-- ==============================================================================

-- 4.1 Auto Profile Creation on Signup
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

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 4.2 Invite Code Generator
CREATE OR REPLACE FUNCTION public.generate_invite_code()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT UPPER(SUBSTRING(MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT) FROM 1 FOR 6));
$$;

-- 4.3 Relationship Partner Check Function
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

-- 4.4 Get Partner User ID Function
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

-- 4.5 Stored Procedure: Join Relationship By Invite Code
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

-- 4.6 Timestamp Auto-Update Trigger
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

DROP TRIGGER IF EXISTS update_profiles_timestamp ON public.profiles;
CREATE TRIGGER update_profiles_timestamp BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS update_relationships_timestamp ON public.relationships;
CREATE TRIGGER update_relationships_timestamp BEFORE UPDATE ON public.relationships FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Revoke public execution on internal trigger functions only
REVOKE ALL ON FUNCTION public.handle_new_user() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.handle_updated_at() FROM PUBLIC, anon;

-- Grant execution on security helper functions so RLS policies can evaluate them
GRANT EXECUTE ON FUNCTION public.get_partner_user_id() TO PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.is_relationship_partner(UUID) TO PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.join_relationship_by_code(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.generate_invite_code() TO PUBLIC, anon, authenticated;

-- ==============================================================================
-- 5. ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================
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
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.connection_requests ENABLE ROW LEVEL SECURITY;

-- 5.1 Profiles RLS
DROP POLICY IF EXISTS "Profiles viewable by authenticated users" ON public.profiles;
CREATE POLICY "Profiles viewable by authenticated users" ON public.profiles FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
CREATE POLICY "Users can insert their own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- 5.2 Relationships RLS
DROP POLICY IF EXISTS "Relationships viewable by participants" ON public.relationships;
CREATE POLICY "Relationships viewable by participants" ON public.relationships FOR SELECT USING (auth.uid() = user1_id OR auth.uid() = user2_id OR (status = 'pending' AND invite_code IS NOT NULL));

DROP POLICY IF EXISTS "Authenticated users can create relationship" ON public.relationships;
CREATE POLICY "Authenticated users can create relationship" ON public.relationships FOR INSERT WITH CHECK (auth.uid() = user1_id);

DROP POLICY IF EXISTS "Participants can update their relationship" ON public.relationships;
CREATE POLICY "Participants can update their relationship" ON public.relationships FOR UPDATE USING (auth.uid() = user1_id OR auth.uid() = user2_id);

-- 5.3 Messages & Receipts RLS
DROP POLICY IF EXISTS "Messages viewable only by relationship partners" ON public.messages;
CREATE POLICY "Messages viewable only by relationship partners" ON public.messages FOR SELECT USING (public.is_relationship_partner(relationship_id));

DROP POLICY IF EXISTS "Partners can send messages" ON public.messages;
CREATE POLICY "Partners can send messages" ON public.messages FOR INSERT WITH CHECK (public.is_relationship_partner(relationship_id) AND auth.uid() = sender_id);

DROP POLICY IF EXISTS "Senders can edit or soft-delete messages" ON public.messages;
CREATE POLICY "Senders can edit or soft-delete messages" ON public.messages FOR UPDATE USING (public.is_relationship_partner(relationship_id) AND auth.uid() = sender_id);

DROP POLICY IF EXISTS "Receipts access for relationship partners" ON public.message_receipts;
CREATE POLICY "Receipts access for relationship partners" ON public.message_receipts FOR ALL USING (EXISTS (SELECT 1 FROM public.messages m WHERE m.id = message_receipts.message_id AND public.is_relationship_partner(m.relationship_id)));

DROP POLICY IF EXISTS "Reactions access for relationship partners" ON public.message_reactions;
CREATE POLICY "Reactions access for relationship partners" ON public.message_reactions FOR ALL USING (EXISTS (SELECT 1 FROM public.messages m WHERE m.id = message_reactions.message_id AND public.is_relationship_partner(m.relationship_id)));

-- 5.4 Calls, Signals, Games & Love Notes RLS
DROP POLICY IF EXISTS "Calls viewable by participants" ON public.calls;
CREATE POLICY "Calls viewable by participants" ON public.calls FOR SELECT USING (public.is_relationship_partner(relationship_id));

DROP POLICY IF EXISTS "Partners can initiate calls" ON public.calls;
CREATE POLICY "Partners can initiate calls" ON public.calls FOR INSERT WITH CHECK (public.is_relationship_partner(relationship_id) AND auth.uid() = caller_id);

DROP POLICY IF EXISTS "Partners can update call status" ON public.calls;
CREATE POLICY "Partners can update call status" ON public.calls FOR UPDATE USING (public.is_relationship_partner(relationship_id));

DROP POLICY IF EXISTS "Signals viewable by call participants" ON public.call_signals;
CREATE POLICY "Signals viewable by call participants" ON public.call_signals FOR ALL USING (EXISTS (SELECT 1 FROM public.calls c WHERE c.id = call_signals.call_id AND public.is_relationship_partner(c.relationship_id)));

DROP POLICY IF EXISTS "Love notes viewable when unlocked" ON public.love_notes;
CREATE POLICY "Love notes viewable when unlocked" ON public.love_notes FOR SELECT USING (public.is_relationship_partner(relationship_id) AND (auth.uid() = sender_id OR unlock_at <= NOW()));

DROP POLICY IF EXISTS "Senders can create love notes" ON public.love_notes;
CREATE POLICY "Senders can create love notes" ON public.love_notes FOR INSERT WITH CHECK (public.is_relationship_partner(relationship_id) AND auth.uid() = sender_id);

DROP POLICY IF EXISTS "Games accessible to relationship partners" ON public.game_sessions;
CREATE POLICY "Games accessible to relationship partners" ON public.game_sessions FOR ALL USING (public.is_relationship_partner(relationship_id));

-- 5.5 Memories, Plans & Vault RLS
DROP POLICY IF EXISTS "Memories accessible to relationship partners" ON public.memories;
CREATE POLICY "Memories accessible to relationship partners" ON public.memories FOR ALL USING (public.is_relationship_partner(relationship_id));

DROP POLICY IF EXISTS "Vault items viewable only by relationship partners" ON public.vault_items;
CREATE POLICY "Vault items viewable only by relationship partners" ON public.vault_items FOR SELECT USING (public.is_relationship_partner(relationship_id));

DROP POLICY IF EXISTS "Partners can insert vault items" ON public.vault_items;
CREATE POLICY "Partners can insert vault items" ON public.vault_items FOR INSERT WITH CHECK (public.is_relationship_partner(relationship_id) AND auth.uid() = owner_id);

DROP POLICY IF EXISTS "Date plans accessible to relationship partners" ON public.date_plans;
CREATE POLICY "Date plans accessible to relationship partners" ON public.date_plans FOR ALL USING (public.is_relationship_partner(relationship_id));

DROP POLICY IF EXISTS "Bucket list accessible to relationship partners" ON public.bucket_list;
CREATE POLICY "Bucket list accessible to relationship partners" ON public.bucket_list FOR ALL USING (public.is_relationship_partner(relationship_id));

DROP POLICY IF EXISTS "Shared goals accessible to relationship partners" ON public.shared_goals;
CREATE POLICY "Shared goals accessible to relationship partners" ON public.shared_goals FOR ALL USING (public.is_relationship_partner(relationship_id));

-- 5.6 Posts & Connection Requests RLS
DROP POLICY IF EXISTS "Posts viewable by all authenticated users" ON public.posts;
CREATE POLICY "Posts viewable by all authenticated users" ON public.posts FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Users can create their own posts" ON public.posts;
CREATE POLICY "Users can create their own posts" ON public.posts FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own posts" ON public.posts;
CREATE POLICY "Users can delete their own posts" ON public.posts FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Requests viewable by sender and receiver" ON public.connection_requests;
CREATE POLICY "Requests viewable by sender and receiver" ON public.connection_requests FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

DROP POLICY IF EXISTS "Users can send connection requests" ON public.connection_requests;
CREATE POLICY "Users can send connection requests" ON public.connection_requests FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- ==============================================================================
-- 6. STORAGE BUCKETS
-- ==============================================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
    ('avatars', 'avatars', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']),
    ('chat_media', 'chat_media', false, 52428800, ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'video/mp4', 'video/quicktime', 'audio/m4a', 'audio/mp4', 'audio/aac', 'audio/mpeg', 'application/pdf']),
    ('memories', 'memories', false, 104857600, ARRAY['image/jpeg', 'image/png', 'image/webp', 'video/mp4', 'audio/m4a', 'audio/mp4', 'audio/mpeg']),
    ('vault_media', 'vault_media', false, 104857600, NULL)
ON CONFLICT (id) DO UPDATE SET 
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- ==============================================================================
-- 7. REALTIME REPLICATION PUBLICATION
-- ==============================================================================
DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.relationships;
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.calls;
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.connection_requests;
EXCEPTION WHEN duplicate_object THEN null; END $$;
