-- ==============================================================================
-- HAVEN: PRODUCTION POSTGRESQL SCHEMA FOR COUPLES APPLICATION
-- ==============================================================================

-- Enable UUID Extension and Cryptographic functions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- 1. USERS & PROFILES TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT NOT NULL,
    nickname TEXT,
    avatar_url TEXT,
    mood TEXT DEFAULT 'loved',
    mood_emoji TEXT DEFAULT '🥰',
    mood_updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_seen TIMESTAMPTZ DEFAULT NOW(),
    is_online BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);

-- ==============================================================================
-- 2. RELATIONSHIPS TABLE (Exactly two users per relationship)
-- ==============================================================================
CREATE TYPE relationship_status AS ENUM ('pending', 'active', 'paused', 'disconnected');

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
    -- Enforce uniqueness of two-user pairing
    CONSTRAINT unique_couple_pair UNIQUE (user1_id, user2_id),
    CONSTRAINT different_partners CHECK (user1_id <> user2_id)
);

CREATE INDEX IF NOT EXISTS idx_relationships_user1 ON public.relationships(user1_id);
CREATE INDEX IF NOT EXISTS idx_relationships_user2 ON public.relationships(user2_id);
CREATE INDEX IF NOT EXISTS idx_relationships_invite_code ON public.relationships(invite_code);

-- ==============================================================================
-- 3. CHAT MESSAGES & INTERACTIONS
-- ==============================================================================
CREATE TYPE message_type AS ENUM ('text', 'image', 'video', 'voice', 'document', 'location', 'game_invite');

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

-- Message Receipts (Delivered / Read status)
CREATE TYPE receipt_status AS ENUM ('sent', 'delivered', 'read');

CREATE TABLE IF NOT EXISTS public.message_receipts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status receipt_status NOT NULL DEFAULT 'sent',
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_message_user_receipt UNIQUE (message_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_receipts_message ON public.message_receipts(message_id);

-- Message Reactions
CREATE TABLE IF NOT EXISTS public.message_reactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    reaction TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_message_user_reaction UNIQUE (message_id, user_id)
);

-- ==============================================================================
-- 4. CALLS & WEBRTC SIGNALING
-- ==============================================================================
CREATE TYPE call_type AS ENUM ('audio', 'video');
CREATE TYPE call_status AS ENUM ('initiating', 'ringing', 'accepted', 'rejected', 'ended', 'missed');

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

-- WebRTC Signaling Exchange Table (Fallback for Realtime Broadcast Channels)
CREATE TYPE signal_type AS ENUM ('offer', 'answer', 'ice_candidate', 'bye');

CREATE TABLE IF NOT EXISTS public.call_signals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    call_id UUID NOT NULL REFERENCES public.calls(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    signal_type signal_type NOT NULL,
    payload JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_signals_call ON public.call_signals(call_id, created_at ASC);

-- ==============================================================================
-- 5. PRIVATE VAULT (Encrypted Items Protected with Biometrics & Keys)
-- ==============================================================================
CREATE TYPE vault_item_type AS ENUM ('photo', 'video', 'note', 'voice_memo', 'document');

CREATE TABLE IF NOT EXISTS public.vault_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    relationship_id UUID NOT NULL REFERENCES public.relationships(id) ON DELETE CASCADE,
    owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    item_type vault_item_type NOT NULL,
    title TEXT NOT NULL,
    encrypted_payload TEXT NOT NULL, -- AES-256-GCM encrypted ciphertext
    iv TEXT NOT NULL,                -- Initialization Vector / Nonce
    auth_tag TEXT NOT NULL,          -- GCM Authentication Tag
    media_url TEXT,                  -- Optional encrypted file link in storage
    file_size_bytes BIGINT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_vault_relationship ON public.vault_items(relationship_id, created_at DESC);

-- ==============================================================================
-- 6. SHARED MEMORIES & TIMELINE
-- ==============================================================================
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
    category TEXT DEFAULT 'general', -- e.g. 'Anniversary', 'First Trip', 'Date Night'
    is_favorite BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_memories_timeline ON public.memories(relationship_id, memory_date DESC);

-- ==============================================================================
-- 7. DATE PLANNER & CALENDAR
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.date_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    relationship_id UUID NOT NULL REFERENCES public.relationships(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    category TEXT DEFAULT 'dinner', -- 'dinner', 'trip', 'movie', 'outdoor', 'indoor'
    scheduled_for TIMESTAMPTZ NOT NULL,
    location_name TEXT,
    budget NUMERIC(10, 2) DEFAULT 0.00,
    currency VARCHAR(3) DEFAULT 'USD',
    checklist JSONB DEFAULT '[]'::JSONB, -- Array of {id, item, is_done}
    notes TEXT,
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_date_plans ON public.date_plans(relationship_id, scheduled_for ASC);

-- ==============================================================================
-- 8. SHARED BUCKET LIST
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.bucket_list (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    relationship_id UUID NOT NULL REFERENCES public.relationships(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    category TEXT DEFAULT 'travel', -- 'travel', 'experience', 'learning', 'lifestyle'
    target_date DATE,
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMPTZ,
    photos TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bucket_list ON public.bucket_list(relationship_id, created_at DESC);

-- ==============================================================================
-- 9. SHARED GOALS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.shared_goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    relationship_id UUID NOT NULL REFERENCES public.relationships(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    category TEXT DEFAULT 'finance', -- 'finance', 'habit', 'travel', 'health'
    target_amount NUMERIC(12, 2) NOT NULL,
    current_amount NUMERIC(12, 2) DEFAULT 0.00,
    currency VARCHAR(3) DEFAULT 'USD',
    target_date DATE,
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_shared_goals ON public.shared_goals(relationship_id);

-- ==============================================================================
-- 10. LOVE NOTES (Instant & Time-Locked Future Messages)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.love_notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    relationship_id UUID NOT NULL REFERENCES public.relationships(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    unlock_at TIMESTAMPTZ DEFAULT NOW(),
    is_opened BOOLEAN DEFAULT false,
    opened_at TIMESTAMPTZ,
    theme_style TEXT DEFAULT 'champagne',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_love_notes ON public.love_notes(relationship_id, unlock_at DESC);

-- ==============================================================================
-- 11. TOGETHER MODE & COUPLE GAMES
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.game_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    relationship_id UUID NOT NULL REFERENCES public.relationships(id) ON DELETE CASCADE,
    game_type TEXT NOT NULL, -- 'would_you_rather', 'truth_or_dare', 'trivia', 'who_is_more_likely'
    current_state JSONB NOT NULL DEFAULT '{}'::JSONB,
    scores JSONB NOT NULL DEFAULT '{}'::JSONB,
    active_turn_user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT true,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_game_sessions ON public.game_sessions(relationship_id);

-- ==============================================================================
-- 12. USER DEVICES & SESSIONS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    device_token TEXT,
    device_name TEXT NOT NULL,
    platform TEXT NOT NULL, -- 'android', 'ios', 'web'
    app_version TEXT,
    last_active_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_user_device UNIQUE (user_id, device_token)
);

CREATE INDEX IF NOT EXISTS idx_devices_user ON public.devices(user_id);
