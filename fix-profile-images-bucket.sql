-- Fix profile-images bucket issue
-- This script ensures the profile-images bucket exists and has proper RLS policies

-- Create the profile-images bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public) 
VALUES ('profile-images', 'profile-images', true)
ON CONFLICT (id) DO NOTHING;

-- Create RLS policies for profile-images bucket
-- Allow users to upload their own profile images
CREATE POLICY "Users can upload their own profile images" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'profile-images' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Allow users to view their own profile images
CREATE POLICY "Users can view their own profile images" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'profile-images' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Allow users to update their own profile images
CREATE POLICY "Users can update their own profile images" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'profile-images' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Allow users to delete their own profile images
CREATE POLICY "Users can delete their own profile images" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'profile-images' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Allow public access to profile images (for viewing other users' profiles)
CREATE POLICY "Public can view profile images" ON storage.objects
    FOR SELECT USING (bucket_id = 'profile-images');

-- Enable RLS on storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
