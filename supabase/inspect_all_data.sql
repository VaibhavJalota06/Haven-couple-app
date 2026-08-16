-- ==============================================================================
-- HAVEN: INSPECT ALL LIVE DATA IN SUPABASE SQL EDITOR
-- Paste and run this script in your Supabase Dashboard -> SQL Editor (New Query -> Run)
-- ==============================================================================

-- 1. Summary of total row counts across all Haven tables
SELECT 'profiles' AS table_name, count(*) AS total_rows FROM public.profiles
UNION ALL
SELECT 'relationships' AS table_name, count(*) AS total_rows FROM public.relationships
UNION ALL
SELECT 'messages' AS table_name, count(*) AS total_rows FROM public.messages
UNION ALL
SELECT 'memories' AS table_name, count(*) AS total_rows FROM public.memories
UNION ALL
SELECT 'date_plans' AS table_name, count(*) AS total_rows FROM public.date_plans
UNION ALL
SELECT 'bucket_list' AS table_name, count(*) AS total_rows FROM public.bucket_list
UNION ALL
SELECT 'shared_goals' AS table_name, count(*) AS total_rows FROM public.shared_goals
UNION ALL
SELECT 'vault_items' AS table_name, count(*) AS total_rows FROM public.vault_items
UNION ALL
SELECT 'posts' AS table_name, count(*) AS total_rows FROM public.posts
UNION ALL
SELECT 'connection_requests' AS table_name, count(*) AS total_rows FROM public.connection_requests;

-- 2. View all Registered User Profiles
SELECT id, email, full_name, nickname, mood, mood_emoji, created_at FROM public.profiles ORDER BY created_at DESC;

-- 3. View all Active/Pending Couple Relationships
SELECT id, user1_id, user2_id, invite_code, status, custom_nickname, anniversary_date, created_at FROM public.relationships ORDER BY created_at DESC;

-- 4. View all Live Chat Messages
SELECT id, relationship_id, sender_id, content, media_type, is_pinned, is_starred, created_at FROM public.messages ORDER BY created_at DESC;

-- 5. View all Couple Date Plans
SELECT id, relationship_id, title, category, scheduled_for, budget, is_completed, created_at FROM public.date_plans ORDER BY scheduled_for ASC;

-- 6. View all Shared Bucket List Items
SELECT id, relationship_id, title, category, target_date, is_completed, created_at FROM public.bucket_list ORDER BY created_at DESC;

-- 7. View all Shared Savings Goals
SELECT id, relationship_id, title, category, target_amount, current_amount, currency, is_completed, created_at FROM public.shared_goals ORDER BY created_at DESC;

-- 8. View all Feed Posts & Reels
SELECT id, user_id, media_url, media_type, caption, location_name, created_at FROM public.posts ORDER BY created_at DESC;
