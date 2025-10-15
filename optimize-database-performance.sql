-- Database Performance Optimization Script
-- This script addresses Supabase Performance Advisor warnings

-- ==============================================
-- 1. OPTIMIZE RLS POLICIES (Auth RLS Initialization Plan)
-- ==============================================

-- Fix profiles table policies
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view public profiles" ON profiles;

CREATE POLICY "Users can insert their own profile" ON profiles
    FOR INSERT WITH CHECK ((select auth.uid()) = id::uuid);

CREATE POLICY "Users can update their own profile" ON profiles
    FOR UPDATE USING ((select auth.uid()) = id::uuid);

CREATE POLICY "Users can view public profiles" ON profiles
    FOR SELECT USING (NOT is_private OR (select auth.uid()) = id::uuid);

-- Fix meals table policies
DROP POLICY IF EXISTS "Users can insert their own meals" ON meals;
DROP POLICY IF EXISTS "Users can view their own meals" ON meals;
DROP POLICY IF EXISTS "Users can update their own meals" ON meals;
DROP POLICY IF EXISTS "Users can delete their own meals" ON meals;

CREATE POLICY "Users can insert their own meals" ON meals
    FOR INSERT WITH CHECK ((select auth.uid()) = user_id::uuid);

CREATE POLICY "Users can view their own meals" ON meals
    FOR SELECT USING ((select auth.uid()) = user_id::uuid);

CREATE POLICY "Users can update their own meals" ON meals
    FOR UPDATE USING ((select auth.uid()) = user_id::uuid);

CREATE POLICY "Users can delete their own meals" ON meals
    FOR DELETE USING ((select auth.uid()) = user_id::uuid);

-- Fix saved_meals table policies
DROP POLICY IF EXISTS "Users can insert their own saved meals" ON saved_meals;
DROP POLICY IF EXISTS "Users can view their own saved meals" ON saved_meals;
DROP POLICY IF EXISTS "Users can update their own saved meals" ON saved_meals;
DROP POLICY IF EXISTS "Users can delete their own saved meals" ON saved_meals;

CREATE POLICY "Users can insert their own saved meals" ON saved_meals
    FOR INSERT WITH CHECK ((select auth.uid()) = user_id::uuid);

CREATE POLICY "Users can view their own saved meals" ON saved_meals
    FOR SELECT USING ((select auth.uid()) = user_id::uuid);

CREATE POLICY "Users can update their own saved meals" ON saved_meals
    FOR UPDATE USING ((select auth.uid()) = user_id::uuid);

CREATE POLICY "Users can delete their own saved meals" ON saved_meals
    FOR DELETE USING ((select auth.uid()) = user_id::uuid);

-- Fix friend_requests table policies
DROP POLICY IF EXISTS "Users can view friend requests they sent or received" ON friend_requests;
DROP POLICY IF EXISTS "Users can insert friend requests" ON friend_requests;
DROP POLICY IF EXISTS "Users can update friend requests they received" ON friend_requests;
DROP POLICY IF EXISTS "Users can delete friend requests they sent" ON friend_requests;

CREATE POLICY "Users can view friend requests they sent or received" ON friend_requests
    FOR SELECT USING (
        (select auth.uid()) = from_user_id::uuid OR 
        (select auth.uid()) = to_user_id::uuid
    );

CREATE POLICY "Users can insert friend requests" ON friend_requests
    FOR INSERT WITH CHECK ((select auth.uid()) = from_user_id::uuid);

CREATE POLICY "Users can update friend requests they received" ON friend_requests
    FOR UPDATE USING ((select auth.uid()) = to_user_id::uuid);

CREATE POLICY "Users can delete friend requests they sent" ON friend_requests
    FOR DELETE USING ((select auth.uid()) = from_user_id::uuid);

-- Fix friendships table policies
DROP POLICY IF EXISTS "Users can insert friendships" ON friendships;
DROP POLICY IF EXISTS "Users can view their own friendships" ON friendships;
DROP POLICY IF EXISTS "Users can delete their own friendships" ON friendships;

CREATE POLICY "Users can insert friendships" ON friendships
    FOR INSERT WITH CHECK (
        (select auth.uid()) = user_id_1::uuid OR 
        (select auth.uid()) = user_id_2::uuid
    );

CREATE POLICY "Users can view their own friendships" ON friendships
    FOR SELECT USING (
        (select auth.uid()) = user_id_1::uuid OR 
        (select auth.uid()) = user_id_2::uuid
    );

CREATE POLICY "Users can delete their own friendships" ON friendships
    FOR DELETE USING (
        (select auth.uid()) = user_id_1::uuid OR 
        (select auth.uid()) = user_id_2::uuid
    );

-- Fix shared_meals table policies
DROP POLICY IF EXISTS "Users can insert shared meals" ON shared_meals;
DROP POLICY IF EXISTS "Users can view meals shared with them" ON shared_meals;

CREATE POLICY "Users can insert shared meals" ON shared_meals
    FOR INSERT WITH CHECK ((select auth.uid()) = shared_by_user_id::uuid);

CREATE POLICY "Users can view meals shared with them" ON shared_meals
    FOR SELECT USING (
        (select auth.uid()) = shared_by_user_id::uuid OR 
        (select auth.uid()) = shared_with_user_id::uuid
    );

-- Fix food_scans table policies
DROP POLICY IF EXISTS "Users can insert their own food scans" ON food_scans;
DROP POLICY IF EXISTS "Users can view their own food scans" ON food_scans;

CREATE POLICY "Users can insert their own food scans" ON food_scans
    FOR INSERT WITH CHECK ((select auth.uid()) = user_id::uuid);

CREATE POLICY "Users can view their own food scans" ON food_scans
    FOR SELECT USING ((select auth.uid()) = user_id::uuid);

-- Fix daily_stats table policies
DROP POLICY IF EXISTS "Users can insert their own daily stats" ON daily_stats;
DROP POLICY IF EXISTS "Users can update their own daily stats" ON daily_stats;
DROP POLICY IF EXISTS "Users can view their own daily stats" ON daily_stats;

CREATE POLICY "Users can insert their own daily stats" ON daily_stats
    FOR INSERT WITH CHECK ((select auth.uid()) = user_id::uuid);

CREATE POLICY "Users can update their own daily stats" ON daily_stats
    FOR UPDATE USING ((select auth.uid()) = user_id::uuid);

CREATE POLICY "Users can view their own daily stats" ON daily_stats
    FOR SELECT USING ((select auth.uid()) = user_id::uuid);

-- ==============================================
-- 2. FIX MULTIPLE PERMISSIVE POLICIES
-- ==============================================

-- Remove duplicate friendship policies
DROP POLICY IF EXISTS "Users can view their friendships" ON friendships;

-- ==============================================
-- 3. ADD MISSING INDEXES FOR FOREIGN KEYS
-- ==============================================

-- Add indexes for foreign keys that are missing (only if tables exist)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'saved_meals') THEN
        CREATE INDEX IF NOT EXISTS idx_saved_meals_original_meal_id ON saved_meals(original_meal_id);
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'shared_meals') THEN
        CREATE INDEX IF NOT EXISTS idx_shared_meals_meal_id ON shared_meals(meal_id);
        CREATE INDEX IF NOT EXISTS idx_shared_meals_shared_by_user_id ON shared_meals(shared_by_user_id);
    END IF;
END $$;

-- ==============================================
-- 4. REMOVE UNUSED INDEXES
-- ==============================================

-- Remove unused indexes (safe to run even if they don't exist)
DROP INDEX IF EXISTS idx_shared_meals_shared_with_user_id;
DROP INDEX IF EXISTS idx_daily_stats_user_id_date;
DROP INDEX IF EXISTS idx_friend_requests_from_user_id;

-- ==============================================
-- 5. SECURITY IMPROVEMENTS
-- ==============================================

-- Fix function search path security issues (only for existing functions)
-- Check if functions exist before trying to alter them
DO $$
BEGIN
    -- Only alter functions that actually exist
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'handle_accepted_friend_request') THEN
        EXECUTE 'ALTER FUNCTION handle_accepted_friend_request() SET search_path = public';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'update_updated_at_column') THEN
        EXECUTE 'ALTER FUNCTION update_updated_at_column() SET search_path = public';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'trigger_update_daily_stats') THEN
        EXECUTE 'ALTER FUNCTION trigger_update_daily_stats() SET search_path = public';
    END IF;
END $$;

-- ==============================================
-- 6. VERIFICATION
-- ==============================================

-- Check that policies are optimized
SELECT 
    schemaname, 
    tablename, 
    policyname, 
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public' 
AND policyname LIKE '%Users%'
ORDER BY tablename, policyname;

-- Check indexes
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE schemaname = 'public' 
AND indexname LIKE 'idx_%'
ORDER BY tablename, indexname;

SELECT 'Database optimization completed successfully!' as status;
