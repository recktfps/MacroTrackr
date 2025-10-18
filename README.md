# MacroTrackr - Food Tracking iPhone App

A comprehensive food tracking iPhone app built with SwiftUI that helps users monitor their nutrition intake, track macros, and connect with friends for motivation and meal sharing.

## 🌟 Features

### Core Functionality
- **Daily Macro Tracking**: Monitor calories, protein, carbohydrates, fat, sugar, and fiber
- **Meal Logging**: Add meals with photos, ingredients, and cooking instructions
- **Food Scanning**: AI-powered food recognition using Vision framework
- **Search & Favorites**: Find previous meals and save favorites for quick access
- **Quick Add**: Add saved meals to current day intake with one tap

### Social Features
- **Friend System**: Connect with friends and share meals
- **Meal Sharing**: Share favorite recipes and meals with friends
- **Profile Highlights**: Showcase favorite meals on your profile
- **Privacy Controls**: Control visibility of your stats and meals

### Analytics & Insights
- **Daily View**: See current intake vs goals with progress indicators
- **Statistics**: View weekly, monthly, and yearly nutrition trends
- **Calendar View**: Visual calendar showing daily nutrition progress
- **Progress Tracking**: Detailed macro progress with remaining amounts

### iOS Integration
- **Home Screen Widget**: Quick view of daily macro progress on home screen
- **Multiple Widget Sizes**: Small, medium, and large widget options
- **Real-time Updates**: Widget updates throughout the day
- **iOS 17+ Support**: Built for the latest iOS features

## 🏗️ Technical Architecture

### Frontend
- **SwiftUI**: Modern declarative UI framework
- **iOS 17+**: Latest iOS features and capabilities
- **WidgetKit**: Home screen widget support
- **Vision Framework**: AI food recognition
- **PhotosUI**: Native photo picker integration

### Backend
- **Supabase**: Backend-as-a-Service
  - PostgreSQL database
  - Real-time subscriptions
  - Authentication (Email/Password + Sign in with Apple)
  - File storage
  - Row Level Security

### Key Dependencies
- `Supabase`: Database and authentication
- `RealmSwift`: Local data caching
- `Kingfisher`: Image loading and caching

## 📱 Screenshots

### Main Features
- Daily macro tracking with progress indicators
- Meal entry with photo capture and food scanning
- Search functionality for previous meals
- Statistics and analytics views
- Social features and friend management

### Widget Support
- Small widget: Quick calorie progress
- Medium widget: All macro progress
- Large widget: Detailed daily overview

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 17.0+ target device or simulator
- Supabase account (free plan works great!)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/MacroTrackr.git
   cd MacroTrackr
   ```

2. **Set up Supabase**
   - Create a new project at [supabase.com](https://supabase.com)
   - Run the SQL schema from `supabase-schema.sql`
   - Get your project URL and anon key

3. **Configure the app**
   - Open `MacroTrackr.xcodeproj` in Xcode
   - Set up environment variables:
     - `SUPABASE_URL`: Your Supabase project URL
     - `SUPABASE_ANON_KEY`: Your Supabase anonymous key
     - `USDA_API_KEY`: Your USDA FoodData Central API key (optional)
   - These can be set in Xcode's build settings or through environment variables

4. **Build and run**
   - Select your target device or simulator
   - Build and run the project (⌘+R)

### USDA Food Database Integration

The app uses the USDA FoodData Central API to provide a comprehensive ingredient database:

1. **Get USDA API Key** (Required for online features)
   - Register at [fdc.nal.usda.gov/api-guide.html](https://fdc.nal.usda.gov/api-guide.html)
   - Click "Get API Key" and create a free account
   - Copy your API key (it looks like: `DEMO_KEY` but with your actual key)
   
2. **Configure API Key in Xcode**
   - Open your project in Xcode
   - Select your target → Build Settings
   - Search for "User-Defined"
   - Click the "+" button and add:
     - **Name**: `USDA_API_KEY`
     - **Value**: Your API key from step 1
   - Build and run - the app will now use the USDA database

**Features:**
- Downloads popular ingredients on first launch (requires API key)
- Stores ingredients locally for offline use
- Online search for specific foods via globe icon (requires API key)
- Automatic daily updates of ingredient database
- **Fallback**: Uses local ingredient database if API key is missing

**Note**: Without a USDA API key, the app will use the built-in fallback ingredients and OpenFoodFacts for barcode scanning.

### Supabase Setup

The app uses Supabase for backend services. See `supabase-config.md` for detailed setup instructions.

### Apple Sign In Setup

The app supports Sign in with Apple for secure authentication. See `supabase-apple-config.md` for detailed setup instructions.

**Why Supabase?**
- ✅ Free plan supports thousands of users
- ✅ Built-in authentication and real-time features
- ✅ PostgreSQL with Row Level Security
- ✅ File storage for meal images
- ✅ Easy scaling as your app grows

## 📊 Database Schema

### Core Tables
- `profiles`: User profiles and goals
- `meals`: Daily meal entries
- `saved_meals`: Favorite/reusable meals
- `friend_requests`: Friend system
- `friendships`: Established friendships
- `shared_meals`: Social meal sharing
- `food_scans`: AI scan history
- `daily_stats`: Cached statistics

### Security
- Row Level Security (RLS) for data isolation
- User authentication with JWT tokens
- Secure file storage with access controls
- Privacy controls for social features

## 🔧 Configuration

### Supabase Configuration
Update the following in `MacroTrackrApp.swift`:

```swift
private let supabase = SupabaseClient(
    supabaseURL: URL(string: "YOUR_SUPABASE_URL")!,
    supabaseKey: "YOUR_SUPABASE_ANON_KEY"
)
```

### Widget Configuration
The widget automatically updates based on your daily meal data. No additional configuration needed.

### Privacy Settings
Users can control:
- Profile visibility (public/private)
- Friend request settings
- Meal sharing preferences
- Anonymous usage analytics

## 📈 Performance Optimizations

### Database
- Optimized indexes for common queries
- Cached daily statistics
- Efficient pagination for meal history
- Real-time subscriptions for social features

### App Performance
- Local caching with Realm
- Image optimization and caching
- Lazy loading for large datasets
- Efficient SwiftUI view updates

### Widget Performance
- Lightweight data fetching
- Efficient timeline updates
- Minimal memory usage
- Fast rendering

## 🔐 Security & Privacy

### Data Protection
- End-to-end encryption for sensitive data
- Secure authentication with Supabase Auth
- Row Level Security for data isolation
- GDPR compliant data handling

### Privacy Features
- User control over data visibility
- Anonymous analytics option
- Secure friend system
- Protected meal sharing

## 🚀 Deployment

### App Store Preparation
1. Update version numbers and build numbers
2. Configure app icons and launch screens
3. Set up App Store Connect
4. Submit for review

### Widget Deployment
- Widget is included in the main app bundle
- No separate deployment needed
- Automatic availability on iOS 14+

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Supabase for providing excellent backend services
- Apple for SwiftUI and iOS development tools
- The open-source community for various libraries and tools

## 📞 Support

If you have any questions or need help:
- Open an issue on GitHub
- Check the documentation in the `docs/` folder
- Review the Supabase configuration guide

## 🗺️ Roadmap

### Planned Features
- [ ] Apple Watch companion app
- [ ] Barcode scanning for packaged foods
- [ ] Recipe scaling and meal planning
- [ ] Integration with fitness apps
- [ ] Advanced analytics and insights
- [ ] Meal prep and batch cooking features
- [ ] Nutritionist consultation features
- [ ] Community challenges and competitions

### Known Issues
- [ ] Food scanning accuracy can be improved
- [ ] Widget updates may have slight delays
- [ ] Large image uploads may take time

---

**Built with ❤️ using SwiftUI and Supabase**