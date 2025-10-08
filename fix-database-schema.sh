#!/bin/bash

# Fix Database Schema for MacroTrackr
# This script applies the necessary database fixes for friend requests and profile images

echo "🔧 Applying database schema fixes for MacroTrackr..."

# Check if psql is available
if ! command -v psql &> /dev/null; then
    echo "❌ psql is not installed. Please install PostgreSQL client tools."
    exit 1
fi

# Database connection details (update these with your Supabase details)
DB_HOST="db.adnjakimzfidaolaxmck.supabase.co"
DB_PORT="5432"
DB_NAME="postgres"
DB_USER="postgres"

echo "📋 Please enter your Supabase database password:"
read -s DB_PASSWORD

# Create the database connection string
DB_URL="postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME"

echo "🔗 Connecting to Supabase database..."

# Apply the schema fixes
echo "📝 Applying profile image storage bucket and policies..."

psql "$DB_URL" -c "
-- Create profile-images storage bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public) 
VALUES ('profile-images', 'profile-images', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for profile images
CREATE POLICY IF NOT EXISTS \"Users can upload their own profile images\" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'profile-images' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY IF NOT EXISTS \"Users can view their own profile images\" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'profile-images' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY IF NOT EXISTS \"Users can update their own profile images\" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'profile-images' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY IF NOT EXISTS \"Users can delete their own profile images\" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'profile-images' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Public read access for profile images
CREATE POLICY IF NOT EXISTS \"Public can view profile images\" ON storage.objects
    FOR SELECT USING (bucket_id = 'profile-images');
"

if [ $? -eq 0 ]; then
    echo "✅ Profile image storage policies applied successfully!"
else
    echo "❌ Failed to apply profile image storage policies."
    exit 1
fi

echo "📝 Fixing friend request constraints..."

psql "$DB_URL" -c "
-- Ensure friend_requests table has proper constraints
ALTER TABLE friend_requests DROP CONSTRAINT IF EXISTS friend_requests_from_user_id_to_user_id_key;
ALTER TABLE friend_requests ADD CONSTRAINT friend_requests_unique_constraint UNIQUE(from_user_id, to_user_id);

-- Ensure friendships table has proper constraints  
ALTER TABLE friendships DROP CONSTRAINT IF EXISTS friendships_user_id_1_user_id_2_key;
ALTER TABLE friendships ADD CONSTRAINT friendships_unique_constraint UNIQUE(user_id_1, user_id_2);
"

if [ $? -eq 0 ]; then
    echo "✅ Friend request constraints fixed successfully!"
else
    echo "❌ Failed to fix friend request constraints."
    exit 1
fi

echo "📝 Updating RLS policies for better friend request handling..."

psql "$DB_URL" -c "
-- Update friend requests policies to be more permissive for testing
DROP POLICY IF EXISTS \"Users can view friend requests they sent or received\" ON friend_requests;
DROP POLICY IF EXISTS \"Users can insert friend requests\" ON friend_requests;
DROP POLICY IF EXISTS \"Users can update friend requests they received\" ON friend_requests;

CREATE POLICY \"Users can view friend requests they sent or received\" ON friend_requests
    FOR SELECT USING (auth.uid()::text = from_user_id OR auth.uid()::text = to_user_id);

CREATE POLICY \"Users can insert friend requests\" ON friend_requests
    FOR INSERT WITH CHECK (auth.uid()::text = from_user_id);

CREATE POLICY \"Users can update friend requests they received\" ON friend_requests
    FOR UPDATE USING (auth.uid()::text = to_user_id);

-- Update profiles policies to allow updates
DROP POLICY IF EXISTS \"Users can update their own profile\" ON profiles;
CREATE POLICY \"Users can update their own profile\" ON profiles
    FOR UPDATE USING (auth.uid()::text = id);

-- Update friendships policies
DROP POLICY IF EXISTS \"Users can insert friendships\" ON friendships;
CREATE POLICY \"Users can insert friendships\" ON friendships
    FOR INSERT WITH CHECK (auth.uid()::text = user_id_1 OR auth.uid()::text = user_id_2);
"

if [ $? -eq 0 ]; then
    echo "✅ RLS policies updated successfully!"
else
    echo "❌ Failed to update RLS policies."
    exit 1
fi

echo "🎉 Database schema fixes applied successfully!"
echo ""
echo "📋 Summary of fixes:"
echo "  ✅ Added profile-images storage bucket"
echo "  ✅ Created profile image storage policies"
echo "  ✅ Fixed friend request constraints"
echo "  ✅ Updated RLS policies for better friend request handling"
echo ""
echo "🚀 Your app should now work properly for:"
echo "  • Profile picture uploads"
echo "  • Friend request sending and receiving"
echo "  • All other features"
echo ""
echo "💡 If you still experience issues, check your Supabase dashboard for any error logs."
