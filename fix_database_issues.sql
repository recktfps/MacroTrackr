-- Fix MacroTrackr Database Issues
-- Run this in your Supabase SQL Editor

-- 1. Ensure profile-images bucket exists and is properly configured
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('profile-images', 'profile-images', true, 52428800, ARRAY['image/jpeg', 'image/png', 'image/gif'])
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- 2. Ensure meal-images bucket exists and is properly configured  
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('meal-images', 'meal-images', true, 52428800, ARRAY['image/jpeg', 'image/png', 'image/gif'])
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- 3. Drop and recreate storage policies to ensure they work correctly
DROP POLICY IF EXISTS "Users can upload their own profile images" ON storage.objects;
DROP POLICY IF EXISTS "Users can view their own profile images" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own profile images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own profile images" ON storage.objects;
DROP POLICY IF EXISTS "Public can view profile images" ON storage.objects;

DROP POLICY IF EXISTS "Users can upload their own meal images" ON storage.objects;
DROP POLICY IF EXISTS "Users can view their own meal images" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own meal images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own meal images" ON storage.objects;
DROP POLICY IF EXISTS "Public can view meal images" ON storage.objects;

-- 4. Create new storage policies for profile images
CREATE POLICY "Users can upload their own profile images" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'profile-images' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can view their own profile images" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'profile-images' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can update their own profile images" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'profile-images' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can delete their own profile images" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'profile-images' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- 5. Create new storage policies for meal images
CREATE POLICY "Users can upload their own meal images" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'meal-images' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can view their own meal images" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'meal-images' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can update their own meal images" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'meal-images' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can delete their own meal images" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'meal-images' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- 6. Create public read policies for both buckets
CREATE POLICY "Public can view profile images" ON storage.objects
    FOR SELECT USING (bucket_id = 'profile-images');

CREATE POLICY "Public can view meal images" ON storage.objects
    FOR SELECT USING (bucket_id = 'meal-images');

-- 7. Ensure the friend request trigger exists and is working
DROP TRIGGER IF EXISTS handle_accepted_friend_request_trigger ON friend_requests;
DROP FUNCTION IF EXISTS handle_accepted_friend_request();

CREATE OR REPLACE FUNCTION handle_accepted_friend_request()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'accepted' AND OLD.status = 'pending' THEN
        INSERT INTO friendships (user_id_1, user_id_2)
        VALUES (
            LEAST(NEW.from_user_id, NEW.to_user_id),
            GREATEST(NEW.from_user_id, NEW.to_user_id)
        )
        ON CONFLICT (user_id_1, user_id_2) DO NOTHING;
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER handle_accepted_friend_request_trigger
    AFTER UPDATE ON friend_requests
    FOR EACH ROW
    EXECUTE FUNCTION handle_accepted_friend_request();

-- 8. Verify all tables exist and have correct structure
DO $$
BEGIN
    -- Check if profiles table exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles') THEN
        RAISE EXCEPTION 'profiles table does not exist. Please run the main schema first.';
    END IF;
    
    -- Check if friend_requests table exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'friend_requests') THEN
        RAISE EXCEPTION 'friend_requests table does not exist. Please run the main schema first.';
    END IF;
    
    -- Check if friendships table exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'friendships') THEN
        RAISE EXCEPTION 'friendships table does not exist. Please run the main schema first.';
    END IF;
    
    RAISE NOTICE 'All required tables exist. Database configuration complete.';
END $$;

-- 9. Check bucket status
SELECT 
    id as bucket_id,
    name as bucket_name,
    public,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets 
WHERE id IN ('profile-images', 'meal-images');

-- 10. Check storage policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'objects' 
AND policyname LIKE '%profile%' OR policyname LIKE '%meal%'
ORDER BY policyname;
