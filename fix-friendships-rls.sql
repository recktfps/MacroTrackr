-- Fix RLS Policy for Friendships Table
-- Run this in your Supabase SQL Editor

-- Add the missing INSERT policy for friendships table
CREATE POLICY "Users can insert friendships" ON friendships
    FOR INSERT WITH CHECK (auth.uid() = user_id_1 OR auth.uid() = user_id_2);

-- Verify the policy was created
SELECT * FROM pg_policies WHERE tablename = 'friendships';
