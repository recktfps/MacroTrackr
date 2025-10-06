# Supabase Configuration for MacroTrackr

## Is Supabase Free Plan Good for This Application?

**Yes, Supabase's free plan is excellent for MacroTrackr!** Here's why:

### Free Plan Limits:
- **Database**: 500MB storage, 2GB bandwidth
- **Auth**: 50,000 monthly active users
- **Storage**: 1GB file storage, 2GB bandwidth
- **Edge Functions**: 500,000 invocations/month
- **Real-time**: 200 concurrent connections

### Perfect for MacroTrackr because:

1. **Database Storage**: 500MB can easily handle thousands of users with meal data, profiles, and social features
2. **Authentication**: 50,000 MAU is more than enough for most apps starting out
3. **File Storage**: 1GB is sufficient for meal images (users typically upload 1-5 images per meal)
4. **Real-time**: Great for live updates between friends sharing meals
5. **Row Level Security**: Built-in security for user data isolation

### When to Upgrade:
- If you exceed 50,000 monthly active users
- If you need more than 1GB of file storage
- If you want to remove the Supabase branding

## Setup Instructions

### 1. Create Supabase Project
1. Go to [supabase.com](https://supabase.com)
2. Create a new project
3. Choose a region close to your users
4. Wait for the project to be ready

### 2. Configure Database
1. Go to the SQL Editor in your Supabase dashboard
2. Copy and paste the contents of `supabase-schema.sql`
3. Execute the SQL to create all tables, indexes, and policies

### 3. Configure Authentication
1. Go to Authentication > Settings
2. Enable email authentication
3. Configure email templates if desired
4. Set up any social providers (Google, Apple, etc.)

### 4. Configure Storage
1. Go to Storage in your dashboard
2. The `meal-images` bucket should be created automatically
3. Configure CORS if needed for web access

### 5. Get API Keys
1. Go to Settings > API
2. Copy your project URL and anon key
3. Update the app configuration with these values

### 6. Environment Variables
Create a `.env` file in your project root:

```env
SUPABASE_URL=your_project_url_here
SUPABASE_ANON_KEY=your_anon_key_here
```

## Database Schema Overview

### Core Tables:
- **profiles**: User profiles with goals and settings
- **meals**: Daily meal entries with macros
- **saved_meals**: Favorite/reusable meals
- **friend_requests**: Friend system management
- **friendships**: Established friendships
- **shared_meals**: Meals shared between friends
- **food_scans**: AI scan history for learning
- **daily_stats**: Cached daily statistics

### Key Features:
- **Row Level Security**: Users can only access their own data
- **Real-time subscriptions**: Live updates for social features
- **Automatic stats calculation**: Daily stats are cached for performance
- **Image storage**: Secure file storage for meal photos
- **Friend system**: Complete social features with privacy controls

## Performance Optimizations

### Indexes:
- Optimized for common queries (user meals, dates, meal types)
- Efficient friend relationship lookups
- Fast search capabilities

### Caching:
- Daily stats are pre-calculated and cached
- Reduces complex aggregation queries
- Improves app responsiveness

### Storage:
- Images stored in Supabase Storage
- CDN delivery for fast image loading
- Automatic image optimization

## Security Features

### Row Level Security:
- Users can only see their own data
- Public profiles visible to friends only
- Secure friend request system
- Protected meal sharing

### Authentication:
- Secure JWT tokens
- Email verification
- Password reset functionality
- Social login support

### Data Privacy:
- User control over profile visibility
- Friend-only meal sharing
- Anonymous usage analytics option
- GDPR compliant data handling

## Monitoring and Analytics

### Built-in Analytics:
- Supabase dashboard shows usage metrics
- Database performance monitoring
- Storage usage tracking
- Auth activity logs

### Custom Metrics:
- Track user engagement
- Monitor feature usage
- Analyze nutrition patterns
- Social feature adoption

## Scaling Considerations

### When Free Plan Isn't Enough:
1. **Pro Plan ($25/month)**:
   - 8GB database storage
   - 100GB bandwidth
   - 100,000 MAU
   - 5GB file storage
   - Priority support

2. **Team Plan ($599/month)**:
   - 8GB database storage
   - 250GB bandwidth
   - 100,000 MAU
   - 100GB file storage
   - Team collaboration features

### Optimization Tips:
- Use database indexes effectively
- Implement proper pagination
- Cache frequently accessed data
- Optimize image sizes before upload
- Use real-time subscriptions efficiently

## Backup and Recovery

### Automatic Backups:
- Supabase provides automatic daily backups
- Point-in-time recovery available
- Database snapshots for major releases

### Data Export:
- Users can export their data
- GDPR compliance for data portability
- JSON export format for easy migration

## Conclusion

Supabase's free plan is perfect for MacroTrackr because:
- ✅ Handles thousands of users
- ✅ Sufficient storage for meal data and images
- ✅ Built-in social features
- ✅ Real-time capabilities
- ✅ Strong security model
- ✅ Easy scaling path

The free plan will easily support your app through initial launch and early growth, with a clear upgrade path when you need more resources.
