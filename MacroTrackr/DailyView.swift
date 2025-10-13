import SwiftUI
import Supabase

struct DailyView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedDate = Date()
    @State private var showingAddMeal = false
    @State private var dailyProgress: MacroProgress = MacroProgress()
    @State private var dailyGoals: MacroGoals = MacroGoals()
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Date Selector
                    DateSelectorView(selectedDate: $selectedDate)
                    
                    // Daily Progress Cards
                    DailyProgressSection(
                        progress: dailyProgress,
                        goals: dailyGoals,
                        meals: dataManager.todayMeals
                    )
                    
                    // Meals List
                    TodaysMealsSection(meals: dataManager.todayMeals)
                    
                    // Quick Add Meal Button
                    QuickAddMealButton {
                        showingAddMeal = true
                    }
                }
                .padding()
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddMeal = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddMeal) {
            AddMealView(selectedDate: selectedDate)
        }
        .onAppear {
            loadDailyData()
        }
        .onChange(of: selectedDate) { _, _ in
            loadDailyData()
        }
    }
    
    private func loadDailyData() {
        guard let userId = authManager.currentUser?.id else { return }
        
        isLoading = true
        
        Task {
            await dataManager.loadTodayMeals(for: userId.uuidString)
            await loadUserGoals(userId: userId.uuidString)
            await calculateDailyProgress()
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func loadUserGoals(userId: String) async {
        do {
            let profiles: [UserProfile] = try await dataManager.supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .execute()
                .value
            
            if let profile = profiles.first {
                await MainActor.run {
                    self.dailyGoals = profile.dailyGoals
                }
            }
        } catch {
            print("Error loading user goals: \(error)")
        }
    }
    
    private func calculateDailyProgress() async {
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
        
        await MainActor.run {
            self.dailyProgress = MacroProgress(
                caloriesProgress: totalMacros.calories,
                proteinProgress: totalMacros.protein,
                carbohydratesProgress: totalMacros.carbohydrates,
                fatProgress: totalMacros.fat,
                sugarProgress: totalMacros.sugar,
                fiberProgress: totalMacros.fiber
            )
        }
    }
}

// MARK: - Date Selector View
struct DateSelectorView: View {
    @Binding var selectedDate: Date
    
    var body: some View {
        HStack {
            Button(action: {
                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
            }
            
            Spacer()
            
            Button(action: {
                selectedDate = Date()
            }) {
                VStack {
                    Text(DateFormatter.fullDateFormatter.string(from: selectedDate))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(DateFormatter.dayFormatter.string(from: selectedDate))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: {
                selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
            }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
            }
            .disabled(Calendar.current.isDateInToday(selectedDate))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Daily Progress Section
struct DailyProgressSection: View {
    let progress: MacroProgress
    let goals: MacroGoals
    let meals: [Meal]
    
    private var totalCalories: Double {
        meals.reduce(0) { $0 + $1.macros.calories }
    }
    
    private var totalProtein: Double {
        meals.reduce(0) { $0 + $1.macros.protein }
    }
    
    private var totalCarbs: Double {
        meals.reduce(0) { $0 + $1.macros.carbohydrates }
    }
    
    private var totalFat: Double {
        meals.reduce(0) { $0 + $1.macros.fat }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Progress")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ProgressCard(
                    title: "Calories",
                    current: totalCalories,
                    goal: goals.calories,
                    unit: "kcal",
                    color: .orange
                )
                
                ProgressCard(
                    title: "Protein",
                    current: totalProtein,
                    goal: goals.protein,
                    unit: "g",
                    color: .red
                )
                
                ProgressCard(
                    title: "Carbs",
                    current: totalCarbs,
                    goal: goals.carbohydrates,
                    unit: "g",
                    color: .blue
                )
                
                ProgressCard(
                    title: "Fat",
                    current: totalFat,
                    goal: goals.fat,
                    unit: "g",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Progress Card
struct ProgressCard: View {
    let title: String
    let current: Double
    let goal: Double
    let unit: String
    let color: Color
    
    private var progressPercentage: Double {
        guard goal > 0 else { return 0 }
        return min(current / goal, 1.0)
    }
    
    private var remaining: Double {
        max(goal - current, 0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(progressPercentage * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(Int(current))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                    
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("/ \(Int(goal))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if remaining > 0 {
                    Text("\(Int(remaining)) \(unit) remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Goal achieved! 🎉")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                }
            }
            
            ProgressView(value: progressPercentage)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(x: 1, y: 0.5)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

// MARK: - Today's Meals Section
struct TodaysMealsSection: View {
    let meals: [Meal]
    
    var mealsByType: [MealType: [Meal]] {
        Dictionary(grouping: meals) { $0.mealType }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Meals")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(meals.count) meals")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if meals.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No meals logged yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Tap the + button to add your first meal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(MealType.allCases, id: \.self) { mealType in
                    if let mealsOfType = mealsByType[mealType], !mealsOfType.isEmpty {
                        MealTypeSection(mealType: mealType, meals: mealsOfType)
                    }
                }
            }
        }
    }
}

// MARK: - Meal Type Section
struct MealTypeSection: View {
    let mealType: MealType
    let meals: [Meal]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: mealType.icon)
                    .foregroundColor(.blue)
                
                Text(mealType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(meals.count) item\(meals.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ForEach(meals) { meal in
                MealRowView(meal: meal)
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
    
    var body: some View {
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
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Meal Info
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.name)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    MacroBadge(label: "Cal", value: "\(Int(meal.macros.calories))", color: .orange)
                    MacroBadge(label: "P", value: "\(Int(meal.macros.protein))g", color: .red)
                    MacroBadge(label: "C", value: "\(Int(meal.macros.carbohydrates))g", color: .blue)
                    MacroBadge(label: "F", value: "\(Int(meal.macros.fat))g", color: .green)
                }
            }
            
            Spacer()
            
            // Time
            Text(DateFormatter.mealDetailFormatter.string(from: meal.createdAt))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Quick Add Meal Button
struct QuickAddMealButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                
                Text("Add Meal")
                    .font(.headline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Today's Meals Section
struct MacroBadge: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .cornerRadius(4)
    }
}

#Preview {
    DailyView()
        .environmentObject(DataManager())
        .environmentObject(AuthenticationManager())
}
