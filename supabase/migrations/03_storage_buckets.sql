-- ==============================================================================
-- HAVEN: SUPABASE STORAGE BUCKETS & STORAGE POLICIES
-- ==============================================================================

-- Create buckets for avatars, chat media, shared memories, and encrypted vault
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
    ('avatars', 'avatars', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']),
    ('chat_media', 'chat_media', false, 52428800, ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'video/mp4', 'video/quicktime', 'audio/m4a', 'audio/mp4', 'audio/aac', 'audio/mpeg', 'application/pdf']),
    ('memories', 'memories', false, 104857600, ARRAY['image/jpeg', 'image/png', 'image/webp', 'video/mp4', 'audio/m4a', 'audio/mp4', 'audio/mpeg']),
    ('vault_media', 'vault_media', false, 104857600, NULL) -- Raw encrypted byte streams
ON CONFLICT (id) DO UPDATE SET 
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- ==============================================================================
-- STORAGE ACCESS POLICIES
-- ==============================================================================

-- Avatars: Public read, owner update
CREATE POLICY "Avatars publicly viewable"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload their avatar"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'avatars' 
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Chat Media: Accessible only to partners in relationship folder: /relationship_id/filename
CREATE POLICY "Chat media accessible to couple"
ON storage.objects FOR SELECT
USING (
    bucket_id = 'chat_media'
    AND public.is_relationship_partner((storage.foldername(name))[1]::UUID)
);

CREATE POLICY "Partners can upload chat media"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'chat_media'
    AND public.is_relationship_partner((storage.foldername(name))[1]::UUID)
);

-- Memories Media: Accessible only to partners in relationship folder
CREATE POLICY "Memories accessible to couple"
ON storage.objects FOR SELECT
USING (
    bucket_id = 'memories'
    AND public.is_relationship_partner((storage.foldername(name))[1]::UUID)
);

CREATE POLICY "Partners can upload memory media"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'memories'
    AND public.is_relationship_partner((storage.foldername(name))[1]::UUID)
);

-- Vault Media: Strictly accessible to couple
CREATE POLICY "Vault media accessible to couple"
ON storage.objects FOR SELECT
USING (
    bucket_id = 'vault_media'
    AND public.is_relationship_partner((storage.foldername(name))[1]::UUID)
);

CREATE POLICY "Partners can upload vault media"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'vault_media'
    AND public.is_relationship_partner((storage.foldername(name))[1]::UUID)
);
