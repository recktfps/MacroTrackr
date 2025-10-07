-- MacroTrackr Database Schema for Supabase
-- This file contains all the necessary tables and configurations for the MacroTrackr app

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create custom types
CREATE TYPE meal_type AS ENUM ('breakfast', 'lunch', 'dinner', 'snack');
CREATE TYPE friend_request_status AS ENUM ('pending', 'accepted', 'declined');

-- User profiles table
CREATE TABLE profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    display_name TEXT NOT NULL,
    email TEXT NOT NULL,
    daily_goals JSONB NOT NULL DEFAULT '{
        "calories": 2000,
        "protein": 150,
        "carbohydrates": 250,
        "fat": 65,
        "sugar": 50,
        "fiber": 25
    }',
    is_private BOOLEAN NOT NULL DEFAULT false,
    favorite_meals TEXT[] DEFAULT '{}',
    profile_image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Meals table
CREATE TABLE meals (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    image_url TEXT,
    ingredients TEXT[] DEFAULT '{}',
    cooking_instructions TEXT,
    macros JSONB NOT NULL DEFAULT '{
        "calories": 0,
        "protein": 0,
        "carbohydrates": 0,
        "fat": 0,
        "sugar": 0,
        "fiber": 0
    }',
    meal_type meal_type NOT NULL DEFAULT 'snack',
    is_favorite BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Saved meals table (for favorite/reusable meals)
CREATE TABLE saved_meals (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    original_meal_id UUID REFERENCES meals(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    image_url TEXT,
    ingredients TEXT[] DEFAULT '{}',
    cooking_instructions TEXT,
    macros JSONB NOT NULL DEFAULT '{
        "calories": 0,
        "protein": 0,
        "carbohydrates": 0,
        "fat": 0,
        "sugar": 0,
        "fiber": 0
    }',
    is_favorite BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Friend requests table
CREATE TABLE friend_requests (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    from_user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    to_user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    status friend_request_status NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(from_user_id, to_user_id)
);

-- Friendships table
CREATE TABLE friendships (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id_1 UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    user_id_2 UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id_1, user_id_2),
    CHECK (user_id_1 < user_id_2)
);

-- Shared meals table (meals shared between friends)
CREATE TABLE shared_meals (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    meal_id UUID REFERENCES meals(id) ON DELETE CASCADE NOT NULL,
    shared_by_user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    shared_with_user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Food scan history table (for AI learning and improvement)
CREATE TABLE food_scans (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    image_url TEXT,
    detected_foods JSONB NOT NULL DEFAULT '[]',
    estimated_macros JSONB NOT NULL DEFAULT '{
        "calories": 0,
        "protein": 0,
        "carbohydrates": 0,
        "fat": 0,
        "sugar": 0,
        "fiber": 0
    }',
    confidence DECIMAL(3,2) NOT NULL DEFAULT 0.0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Daily stats cache table (for performance optimization)
CREATE TABLE daily_stats (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    date DATE NOT NULL,
    total_macros JSONB NOT NULL DEFAULT '{
        "calories": 0,
        "protein": 0,
        "carbohydrates": 0,
        "fat": 0,
        "sugar": 0,
        "fiber": 0
    }',
    goal_progress JSONB NOT NULL DEFAULT '{
        "caloriesProgress": 0,
        "proteinProgress": 0,
        "carbohydratesProgress": 0,
        "fatProgress": 0,
        "sugarProgress": 0,
        "fiberProgress": 0
    }',
    meal_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, date)
);

-- Indexes for better performance
CREATE INDEX idx_meals_user_id_created_at ON meals(user_id, created_at DESC);
CREATE INDEX idx_meals_user_id_meal_type ON meals(user_id, meal_type);
CREATE INDEX idx_saved_meals_user_id ON saved_meals(user_id);
CREATE INDEX idx_friend_requests_to_user_id ON friend_requests(to_user_id);
CREATE INDEX idx_friend_requests_status ON friend_requests(status);
CREATE INDEX idx_friendships_user_id_1 ON friendships(user_id_1);
CREATE INDEX idx_friendships_user_id_2 ON friendships(user_id_2);
CREATE INDEX idx_shared_meals_shared_with_user_id ON shared_meals(shared_with_user_id);
CREATE INDEX idx_food_scans_user_id_created_at ON food_scans(user_id, created_at DESC);
CREATE INDEX idx_daily_stats_user_id_date ON daily_stats(user_id, date);

-- Row Level Security (RLS) policies
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE meals ENABLE ROW LEVEL SECURITY;
ALTER TABLE saved_meals ENABLE ROW LEVEL SECURITY;
ALTER TABLE friend_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_meals ENABLE ROW LEVEL SECURITY;
ALTER TABLE food_scans ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_stats ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view public profiles" ON profiles
    FOR SELECT USING (NOT is_private OR auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Meals policies
CREATE POLICY "Users can view their own meals" ON meals
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own meals" ON meals
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own meals" ON meals
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own meals" ON meals
    FOR DELETE USING (auth.uid() = user_id);

-- Saved meals policies
CREATE POLICY "Users can view their own saved meals" ON saved_meals
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own saved meals" ON saved_meals
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own saved meals" ON saved_meals
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own saved meals" ON saved_meals
    FOR DELETE USING (auth.uid() = user_id);

-- Friend requests policies
CREATE POLICY "Users can view friend requests they sent or received" ON friend_requests
    FOR SELECT USING (auth.uid() = from_user_id OR auth.uid() = to_user_id);

CREATE POLICY "Users can insert friend requests" ON friend_requests
    FOR INSERT WITH CHECK (auth.uid() = from_user_id);

CREATE POLICY "Users can update friend requests they received" ON friend_requests
    FOR UPDATE USING (auth.uid() = to_user_id);

-- Friendships policies
CREATE POLICY "Users can view their friendships" ON friendships
    FOR SELECT USING (auth.uid() = user_id_1 OR auth.uid() = user_id_2);

CREATE POLICY "Users can insert friendships" ON friendships
    FOR INSERT WITH CHECK (auth.uid() = user_id_1 OR auth.uid() = user_id_2);

-- Shared meals policies
CREATE POLICY "Users can view meals shared with them" ON shared_meals
    FOR SELECT USING (auth.uid() = shared_with_user_id OR auth.uid() = shared_by_user_id);

CREATE POLICY "Users can insert shared meals" ON shared_meals
    FOR INSERT WITH CHECK (auth.uid() = shared_by_user_id);

-- Food scans policies
CREATE POLICY "Users can view their own food scans" ON food_scans
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own food scans" ON food_scans
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Daily stats policies
CREATE POLICY "Users can view their own daily stats" ON daily_stats
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own daily stats" ON daily_stats
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own daily stats" ON daily_stats
    FOR UPDATE USING (auth.uid() = user_id);

-- Functions for updating timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updating timestamps
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_meals_updated_at BEFORE UPDATE ON meals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_saved_meals_updated_at BEFORE UPDATE ON saved_meals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_friend_requests_updated_at BEFORE UPDATE ON friend_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_daily_stats_updated_at BEFORE UPDATE ON daily_stats
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to create friendship when friend request is accepted
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

-- Function to calculate and cache daily stats
CREATE OR REPLACE FUNCTION calculate_daily_stats(p_user_id UUID, p_date DATE)
RETURNS VOID AS $$
DECLARE
    v_total_macros JSONB;
    v_goal_progress JSONB;
    v_goals JSONB;
    v_meal_count INTEGER;
BEGIN
    -- Get user's goals
    SELECT daily_goals INTO v_goals FROM profiles WHERE id = p_user_id;
    
    -- Calculate total macros for the day
    SELECT 
        jsonb_build_object(
            'calories', COALESCE(SUM((macros->>'calories')::DECIMAL), 0),
            'protein', COALESCE(SUM((macros->>'protein')::DECIMAL), 0),
            'carbohydrates', COALESCE(SUM((macros->>'carbohydrates')::DECIMAL), 0),
            'fat', COALESCE(SUM((macros->>'fat')::DECIMAL), 0),
            'sugar', COALESCE(SUM((macros->>'sugar')::DECIMAL), 0),
            'fiber', COALESCE(SUM((macros->>'fiber')::DECIMAL), 0)
        ),
        COUNT(*)
    INTO v_total_macros, v_meal_count
    FROM meals 
    WHERE user_id = p_user_id 
    AND DATE(created_at) = p_date;
    
    -- Calculate goal progress
    v_goal_progress := jsonb_build_object(
        'caloriesProgress', (v_total_macros->>'calories')::DECIMAL / NULLIF((v_goals->>'calories')::DECIMAL, 0) * 100,
        'proteinProgress', (v_total_macros->>'protein')::DECIMAL / NULLIF((v_goals->>'protein')::DECIMAL, 0) * 100,
        'carbohydratesProgress', (v_total_macros->>'carbohydrates')::DECIMAL / NULLIF((v_goals->>'carbohydrates')::DECIMAL, 0) * 100,
        'fatProgress', (v_total_macros->>'fat')::DECIMAL / NULLIF((v_goals->>'fat')::DECIMAL, 0) * 100,
        'sugarProgress', (v_total_macros->>'sugar')::DECIMAL / NULLIF((v_goals->>'sugar')::DECIMAL, 0) * 100,
        'fiberProgress', (v_total_macros->>'fiber')::DECIMAL / NULLIF((v_goals->>'fiber')::DECIMAL, 0) * 100
    );
    
    -- Insert or update daily stats
    INSERT INTO daily_stats (user_id, date, total_macros, goal_progress, meal_count)
    VALUES (p_user_id, p_date, v_total_macros, v_goal_progress, v_meal_count)
    ON CONFLICT (user_id, date)
    DO UPDATE SET
        total_macros = EXCLUDED.total_macros,
        goal_progress = EXCLUDED.goal_progress,
        meal_count = EXCLUDED.meal_count,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- Trigger to update daily stats when meals are inserted/updated/deleted
CREATE OR REPLACE FUNCTION trigger_update_daily_stats()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        PERFORM calculate_daily_stats(OLD.user_id, DATE(OLD.created_at));
        RETURN OLD;
    ELSE
        PERFORM calculate_daily_stats(NEW.user_id, DATE(NEW.created_at));
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_daily_stats_on_meal_change
    AFTER INSERT OR UPDATE OR DELETE ON meals
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_daily_stats();

-- Storage bucket for meal images
INSERT INTO storage.buckets (id, name, public) VALUES ('meal-images', 'meal-images', true);

-- Storage policies for meal images
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

-- Public read access for shared meal images
CREATE POLICY "Public can view meal images" ON storage.objects
    FOR SELECT USING (bucket_id = 'meal-images');
