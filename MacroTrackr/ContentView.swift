import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView(selectedTab: $selectedTab)
                    .environmentObject(dataManager)
            } else {
                AuthenticationView()
            }
        }
        .animation(.easeInOut, value: authManager.isAuthenticated)
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DailyView()
                .tabItem {
                    Image(systemName: "calendar.day.timeline.left")
                    Text("Today")
                }
                .tag(0)
            
            AddMealView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Meal")
                }
                .tag(1)
            
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
                .tag(2)
            
            StatsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Stats")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(4)
        }
        .accentColor(.blue)
        .onAppear {
            if let userId = authManager.currentUser?.id {
                Task {
                    await dataManager.loadTodayMeals(for: userId)
                    await dataManager.loadSavedMeals(for: userId)
                }
            }
        }
    }
}

// MARK: - Daily View
struct DailyView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var userGoals = MacroGoals()
    @State private var showingMealDetail = false
    @State private var selectedMeal: Meal?
    
    private var todayProgress: MacroProgress {
        let totalMacros = dataManager.todayMeals.reduce(MacroNutrition()) { total, meal in
            MacroNutrition(
                calories: total.calories + meal.macros.calories,
                protein: total.protein + meal.macros.protein,
                carbohydrates: total.carbohydrates + meal.macros.carbohydrates,
                fat: total.fat + meal.macros.fat,
                sugar: total.sugar + meal.macros.sugar,
                fiber: total.fiber + meal.macros.fiber
            )
        }
        
        return MacroProgress(
            caloriesProgress: (totalMacros.calories / userGoals.calories) * 100,
            proteinProgress: (totalMacros.protein / userGoals.protein) * 100,
            carbohydratesProgress: (totalMacros.carbohydrates / userGoals.carbohydrates) * 100,
            fatProgress: (totalMacros.fat / userGoals.fat) * 100,
            sugarProgress: (totalMacros.sugar / userGoals.sugar) * 100,
            fiberProgress: (totalMacros.fiber / userGoals.fiber) * 100
        )
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Date Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text(DateFormatter.dayFormatter.string(from: Date()))
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Text(DateFormatter.fullDateFormatter.string(from: Date()))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Macro Progress Cards
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        MacroProgressCard(
                            title: "Calories",
                            current: dataManager.todayMeals.reduce(0) { $0 + $1.macros.calories },
                            goal: userGoals.calories,
                            progress: todayProgress.caloriesProgress,
                            unit: "kcal",
                            color: .orange
                        )
                        
                        MacroProgressCard(
                            title: "Protein",
                            current: dataManager.todayMeals.reduce(0) { $0 + $1.macros.protein },
                            goal: userGoals.protein,
                            progress: todayProgress.proteinProgress,
                            unit: "g",
                            color: .red
                        )
                        
                        MacroProgressCard(
                            title: "Carbs",
                            current: dataManager.todayMeals.reduce(0) { $0 + $1.macros.carbohydrates },
                            goal: userGoals.carbohydrates,
                            progress: todayProgress.carbohydratesProgress,
                            unit: "g",
                            color: .blue
                        )
                        
                        MacroProgressCard(
                            title: "Fat",
                            current: dataManager.todayMeals.reduce(0) { $0 + $1.macros.fat },
                            goal: userGoals.fat,
                            progress: todayProgress.fatProgress,
                            unit: "g",
                            color: .green
                        )
                    }
                    .padding(.horizontal)
                    
                    // Sugar & Fiber Row
                    HStack(spacing: 16) {
                        MacroProgressCard(
                            title: "Sugar",
                            current: dataManager.todayMeals.reduce(0) { $0 + $1.macros.sugar },
                            goal: userGoals.sugar,
                            progress: todayProgress.sugarProgress,
                            unit: "g",
                            color: .pink
                        )
                        
                        MacroProgressCard(
                            title: "Fiber",
                            current: dataManager.todayMeals.reduce(0) { $0 + $1.macros.fiber },
                            goal: userGoals.fiber,
                            progress: todayProgress.fiberProgress,
                            unit: "g",
                            color: .brown
                        )
                    }
                    .padding(.horizontal)
                    
                    // Today's Meals
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Today's Meals")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Spacer()
                            Button("Add Meal") {
                                // Switch to Add Meal tab
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                        
                        if dataManager.todayMeals.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "fork.knife.circle")
                                    .font(.system(size: 60))
                                    .foregroundColor(.secondary)
                                Text("No meals logged today")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text("Start tracking your nutrition by adding your first meal!")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ForEach(dataManager.todayMeals) { meal in
                                MealRowView(meal: meal) {
                                    selectedMeal = meal
                                    showingMealDetail = true
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("MacroTrackr")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingMealDetail) {
            if let meal = selectedMeal {
                MealDetailView(meal: meal)
            }
        }
    }
}

// MARK: - Macro Progress Card
struct MacroProgressCard: View {
    let title: String
    let current: Double
    let goal: Double
    let progress: Double
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(Int(current))/\(Int(goal)) \(unit)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress / 100)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            HStack {
                Text("\(Int(progress))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if progress < 100 {
                    Text("\(Int(goal - current)) \(unit) left")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Goal reached!")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Meal Row View
struct MealRowView: View {
    let meal: Meal
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Meal Image
                AsyncImage(url: URL(string: meal.imageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        )
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Meal Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(meal.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(meal.mealType.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        MacroBadge(value: Int(meal.macros.calories), unit: "kcal", color: .orange)
                        MacroBadge(value: Int(meal.macros.protein), unit: "p", color: .red)
                        MacroBadge(value: Int(meal.macros.carbohydrates), unit: "c", color: .blue)
                        MacroBadge(value: Int(meal.macros.fat), unit: "f", color: .green)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Macro Badge
struct MacroBadge: View {
    let value: Int
    let unit: String
    let color: Color
    
    var body: some View {
        Text("\(value)\(unit)")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(6)
    }
}

// MARK: - Date Formatters
extension DateFormatter {
    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()
    
    static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter
    }()
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager())
        .environmentObject(DataManager())
}
