-- Additional tables for new MacroTrackr features
-- Run this AFTER the main supabase-schema.sql

-- Ingredients table (for storing USDA ingredients data)
CREATE TABLE ingredients (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    macros JSONB NOT NULL DEFAULT '{
        "calories": 0,
        "protein": 0,
        "carbohydrates": 0,
        "fat": 0,
        "sugar": 0,
        "fiber": 0
    }',
    category TEXT NOT NULL DEFAULT 'other',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User ingredient presets table (for user's custom ingredients)
CREATE TABLE user_ingredient_presets (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    macros JSONB NOT NULL DEFAULT '{
        "calories": 0,
        "protein": 0,
        "carbohydrates": 0,
        "fat": 0,
        "sugar": 0,
        "fiber": 0
    }',
    category TEXT NOT NULL DEFAULT 'other',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Recipe collections table
CREATE TABLE recipe_collections (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    image_url TEXT,
    ingredients TEXT[] DEFAULT '{}',
    instructions TEXT[] DEFAULT '{}',
    serving_size INTEGER NOT NULL DEFAULT 1,
    prep_time INTEGER, -- in minutes
    cook_time INTEGER, -- in minutes
    macros JSONB NOT NULL DEFAULT '{
        "calories": 0,
        "protein": 0,
        "carbohydrates": 0,
        "fat": 0,
        "sugar": 0,
        "fiber": 0
    }',
    tags TEXT[] DEFAULT '{}',
    is_public BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Recipe ratings table
CREATE TABLE recipe_ratings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    recipe_id UUID REFERENCES recipe_collections(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(recipe_id, user_id)
);

-- Indexes for new tables
CREATE INDEX idx_user_ingredient_presets_user_id ON user_ingredient_presets(user_id);
CREATE INDEX idx_recipe_collections_user_id ON recipe_collections(user_id);
CREATE INDEX idx_recipe_collections_is_public ON recipe_collections(is_public);
CREATE INDEX idx_recipe_collections_created_at ON recipe_collections(created_at DESC);
CREATE INDEX idx_recipe_ratings_recipe_id ON recipe_ratings(recipe_id);
CREATE INDEX idx_recipe_ratings_user_id ON recipe_ratings(user_id);

-- Row Level Security for new tables
ALTER TABLE user_ingredient_presets ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_ratings ENABLE ROW LEVEL SECURITY;

-- User ingredient presets policies
CREATE POLICY "Users can view their own ingredient presets" ON user_ingredient_presets
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own ingredient presets" ON user_ingredient_presets
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own ingredient presets" ON user_ingredient_presets
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own ingredient presets" ON user_ingredient_presets
    FOR DELETE USING (auth.uid() = user_id);

-- Recipe collections policies
CREATE POLICY "Users can view public recipes" ON recipe_collections
    FOR SELECT USING (is_public = true OR auth.uid() = user_id);

CREATE POLICY "Users can insert their own recipes" ON recipe_collections
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own recipes" ON recipe_collections
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own recipes" ON recipe_collections
    FOR DELETE USING (auth.uid() = user_id);

-- Recipe ratings policies
CREATE POLICY "Users can view all recipe ratings" ON recipe_ratings
    FOR SELECT USING (true);

CREATE POLICY "Users can insert their own ratings" ON recipe_ratings
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own ratings" ON recipe_ratings
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own ratings" ON recipe_ratings
    FOR DELETE USING (auth.uid() = user_id);

-- Triggers for updating timestamps on new tables
CREATE TRIGGER update_recipe_collections_updated_at BEFORE UPDATE ON recipe_collections
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
