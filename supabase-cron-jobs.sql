-- MacroTrackr Cron Jobs Configuration
-- Enable pg_cron extension first, then add these jobs

-- ============================================================================
-- ENABLE CRON EXTENSION (Run this first)
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pg_cron;

-- ============================================================================
-- CRON JOB 1: Daily Stats Aggregation (Runs at midnight every day)
-- ============================================================================

-- This job aggregates daily meal data into the daily_stats table for faster queries
SELECT cron.schedule(
    'aggregate-daily-stats',
    '0 0 * * *',  -- Every day at midnight
    $$
    INSERT INTO daily_stats (id, user_id, date, total_calories, total_protein, total_carbs, total_fat, total_sugar, total_fiber, meal_count, created_at)
    SELECT 
        gen_random_uuid(),
        user_id,
        DATE(created_at) as date,
        SUM((macros->>'calories')::numeric) as total_calories,
        SUM((macros->>'protein')::numeric) as total_protein,
        SUM((macros->>'carbohydrates')::numeric) as total_carbs,
        SUM((macros->>'fat')::numeric) as total_fat,
        SUM((macros->>'sugar')::numeric) as total_sugar,
        SUM((macros->>'fiber')::numeric) as total_fiber,
        COUNT(*) as meal_count,
        NOW()
    FROM meals
    WHERE DATE(created_at) = CURRENT_DATE - INTERVAL '1 day'
    GROUP BY user_id, DATE(created_at)
    ON CONFLICT (user_id, date) 
    DO UPDATE SET
        total_calories = EXCLUDED.total_calories,
        total_protein = EXCLUDED.total_protein,
        total_carbs = EXCLUDED.total_carbs,
        total_fat = EXCLUDED.total_fat,
        total_sugar = EXCLUDED.total_sugar,
        total_fiber = EXCLUDED.total_fiber,
        meal_count = EXCLUDED.meal_count,
        updated_at = NOW();
    $$
);

-- ============================================================================
-- CRON JOB 2: Clean Up Old Declined Friend Requests (Runs weekly)
-- ============================================================================

-- Remove declined friend requests older than 30 days to keep database clean
SELECT cron.schedule(
    'cleanup-old-friend-requests',
    '0 2 * * 0',  -- Every Sunday at 2 AM
    $$
    DELETE FROM friend_requests
    WHERE status = 'declined'
    AND updated_at < NOW() - INTERVAL '30 days';
    $$
);

-- ============================================================================
-- CRON JOB 3: Update User Streak Counts (Runs daily)
-- ============================================================================

-- Calculate consecutive days of meal logging for user streaks
SELECT cron.schedule(
    'update-user-streaks',
    '5 0 * * *',  -- Every day at 00:05 (after stats aggregation)
    $$
    UPDATE profiles p
    SET updated_at = NOW()
    -- Add streak calculation logic here when you implement user streaks
    WHERE EXISTS (
        SELECT 1 FROM meals m
        WHERE m.user_id = p.id
        AND DATE(m.created_at) = CURRENT_DATE - INTERVAL '1 day'
    );
    $$
);

-- ============================================================================
-- CRON JOB 4: Clean Up Old Anonymous Food Scans (Runs weekly)
-- ============================================================================

-- Remove food scan data older than 7 days (if you're storing AI scan results)
SELECT cron.schedule(
    'cleanup-old-food-scans',
    '0 3 * * 0',  -- Every Sunday at 3 AM
    $$
    DELETE FROM food_scans
    WHERE created_at < NOW() - INTERVAL '7 days';
    $$
);

-- ============================================================================
-- CRON JOB 5: Refresh Materialized Views (If using any)
-- ============================================================================

-- Refresh any materialized views for performance
-- SELECT cron.schedule(
--     'refresh-materialized-views',
--     '0 1 * * *',  -- Every day at 1 AM
--     $$
--     REFRESH MATERIALIZED VIEW CONCURRENTLY user_stats_summary;
--     $$
-- );

-- ============================================================================
-- VIEW ALL SCHEDULED CRON JOBS
-- ============================================================================

-- Run this to see all active cron jobs:
-- SELECT * FROM cron.job;

-- ============================================================================
-- UNSCHEDULE A JOB (If needed)
-- ============================================================================

-- To remove a cron job:
-- SELECT cron.unschedule('job-name');

-- Example:
-- SELECT cron.unschedule('aggregate-daily-stats');

-- ============================================================================
-- CHECK CRON JOB HISTORY
-- ============================================================================

-- See execution history:
-- SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 100;

-- ============================================================================
-- NOTES
-- ============================================================================

/*
CRON SCHEDULE FORMAT: minute hour day-of-month month day-of-week
- 0 0 * * * = Every day at midnight
- 0 2 * * 0 = Every Sunday at 2 AM
- 0-59/5 * * * * = Every 5 minutes
- 0 0-23/6 * * * = Every 6 hours

BENEFITS FOR MACROTRACKR:
1. Faster stats queries (pre-aggregated data)
2. Cleaner database (old data removed)
3. Better performance
4. Automated maintenance
5. User streak tracking ready

RECOMMENDATIONS:
✅ Enable Job 1 (Daily Stats) - High value
✅ Enable Job 2 (Cleanup) - Good housekeeping
⚠️ Enable Job 3 (Streaks) - When you add streak feature
⚠️ Enable Job 4 (Scans) - When using real AI
❌ Skip Job 5 (Views) - Not using materialized views yet
*/

