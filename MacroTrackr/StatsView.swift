import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedPeriod: StatsPeriod = .week
    @State private var selectedDate = Date()
    @State private var statsData: [DailyStats] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Period Selector
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(StatsPeriod.allCases, id: \.self) { period in
                        Text(period.displayName).tag(period)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedPeriod == .week {
                    // Week selector
                    WeekSelectorView(selectedDate: $selectedDate)
                        .padding(.horizontal)
                } else if selectedPeriod == .month {
                    // Month selector
                    MonthSelectorView(selectedDate: $selectedDate)
                        .padding(.horizontal)
                }
                
                if isLoading {
                    Spacer()
                    ProgressView("Loading stats...")
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Chart Section
                            if !statsData.isEmpty {
                                ChartSectionView(
                                    period: selectedPeriod,
                                    statsData: statsData
                                )
                            }
                            
                            // Summary Cards
                            SummaryCardsView(
                                period: selectedPeriod,
                                statsData: statsData
                            )
                            
                            // Calendar View (if month selected)
                            if selectedPeriod == .month {
                                CalendarStatsView(statsData: statsData)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            loadStats()
        }
        .onChange(of: selectedPeriod) { _, _ in
            loadStats()
        }
        .onChange(of: selectedDate) { _, _ in
            loadStats()
        }
    }
    
    private func loadStats() {
        guard let userId = authManager.currentUser?.id else { return }
        
        isLoading = true
        
        Task {
            let stats = await fetchStats(for: userId, period: selectedPeriod, date: selectedDate)
            
            await MainActor.run {
                self.statsData = stats
                self.isLoading = false
            }
        }
    }
    
    private func fetchStats(for userId: String, period: StatsPeriod, date: Date) async -> [DailyStats] {
        // In a real implementation, this would fetch from Supabase
        // For now, we'll generate mock data
        return generateMockStats(for: period, date: date)
    }
    
    private func generateMockStats(for period: StatsPeriod, date: Date) -> [DailyStats] {
        var stats: [DailyStats] = []
        let calendar = Calendar.current
        
        switch period {
        case .week:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
            for i in 0..<7 {
                if let day = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                    stats.append(createMockDailyStats(for: day))
                }
            }
        case .month:
            let startOfMonth = calendar.dateInterval(of: .month, for: date)?.start ?? date
            let endOfMonth = calendar.dateInterval(of: .month, for: date)?.end ?? date
            var currentDate = startOfMonth
            
            while currentDate < endOfMonth {
                stats.append(createMockDailyStats(for: currentDate))
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
        case .year:
            let startOfYear = calendar.dateInterval(of: .year, for: date)?.start ?? date
            for i in 0..<12 {
                if let month = calendar.date(byAdding: .month, value: i, to: startOfYear) {
                    stats.append(createMockDailyStats(for: month))
                }
            }
        }
        
        return stats
    }
    
    private func createMockDailyStats(for date: Date) -> DailyStats {
        let mockMeals = [
            Meal(
                id: UUID().uuidString,
                userId: "mock",
                name: "Breakfast",
                imageURL: nil,
                ingredients: [],
                cookingInstructions: nil,
                macros: MacroNutrition(calories: 400, protein: 25, carbohydrates: 45, fat: 15, sugar: 10, fiber: 5),
                createdAt: date,
                mealType: .breakfast
            )
        ]
        
        let totalMacros = mockMeals.reduce(MacroNutrition()) { total, meal in
            MacroNutrition(
                calories: total.calories + meal.macros.calories,
                protein: total.protein + meal.macros.protein,
                carbohydrates: total.carbohydrates + meal.macros.carbohydrates,
                fat: total.fat + meal.macros.fat,
                sugar: total.sugar + meal.macros.sugar,
                fiber: total.fiber + meal.macros.fiber
            )
        }
        
        let goals = MacroGoals()
        let progress = MacroProgress(
            caloriesProgress: (totalMacros.calories / goals.calories) * 100,
            proteinProgress: (totalMacros.protein / goals.protein) * 100,
            carbohydratesProgress: (totalMacros.carbohydrates / goals.carbohydrates) * 100,
            fatProgress: (totalMacros.fat / goals.fat) * 100,
            sugarProgress: (totalMacros.sugar / goals.sugar) * 100,
            fiberProgress: (totalMacros.fiber / goals.fiber) * 100
        )
        
        return DailyStats(
            date: date,
            totalMacros: totalMacros,
            meals: mockMeals,
            goalProgress: progress
        )
    }
}

// MARK: - Stats Period
enum StatsPeriod: CaseIterable {
    case week, month, year
    
    var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        }
    }
}

// MARK: - Week Selector
struct WeekSelectorView: View {
    @Binding var selectedDate: Date
    
    private var weekDates: [Date] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        return (0..<7).compactMap { i in
            calendar.date(byAdding: .day, value: i, to: startOfWeek)
        }
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(weekDates, id: \.self) { date in
                    DayButton(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate)
                    ) {
                        selectedDate = date
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Month Selector
struct MonthSelectorView: View {
    @Binding var selectedDate: Date
    
    var body: some View {
        HStack {
            Button(action: {
                selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
            }
            
            Spacer()
            
            Text(DateFormatter.monthYearFormatter.string(from: selectedDate))
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button(action: {
                selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
            }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
            }
        }
        .padding()
    }
}

// MARK: - Day Button
struct DayButton: View {
    let date: Date
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(DateFormatter.dayAbbreviationFormatter.string(from: date))
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .secondary)
                
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.headline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 44, height: 44)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(22)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Chart Section
struct ChartSectionView: View {
    let period: StatsPeriod
    let statsData: [DailyStats]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress Over Time")
                .font(.headline)
                .fontWeight(.semibold)
            
            Chart(statsData, id: \.date) { stat in
                LineMark(
                    x: .value("Date", stat.date),
                    y: .value("Calories", stat.totalMacros.calories)
                )
                .foregroundStyle(.orange)
                
                LineMark(
                    x: .value("Date", stat.date),
                    y: .value("Protein", stat.totalMacros.protein)
                )
                .foregroundStyle(.red)
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Summary Cards
struct SummaryCardsView: View {
    let period: StatsPeriod
    let statsData: [DailyStats]
    
    private var averages: MacroNutrition {
        guard !statsData.isEmpty else { return MacroNutrition() }
        
        let totals = statsData.reduce(MacroNutrition()) { total, stat in
            MacroNutrition(
                calories: total.calories + stat.totalMacros.calories,
                protein: total.protein + stat.totalMacros.protein,
                carbohydrates: total.carbohydrates + stat.totalMacros.carbohydrates,
                fat: total.fat + stat.totalMacros.fat,
                sugar: total.sugar + stat.totalMacros.sugar,
                fiber: total.fiber + stat.totalMacros.fiber
            )
        }
        
        let count = Double(statsData.count)
        return MacroNutrition(
            calories: totals.calories / count,
            protein: totals.protein / count,
            carbohydrates: totals.carbohydrates / count,
            fat: totals.fat / count,
            sugar: totals.sugar / count,
            fiber: totals.fiber / count
        )
    }
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            StatCard(title: "Avg Calories", value: Int(averages.calories), unit: "kcal", color: .orange)
            StatCard(title: "Avg Protein", value: Int(averages.protein), unit: "g", color: .red)
            StatCard(title: "Avg Carbs", value: Int(averages.carbohydrates), unit: "g", color: .blue)
            StatCard(title: "Avg Fat", value: Int(averages.fat), unit: "g", color: .green)
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: Int
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(alignment: .bottom, spacing: 4) {
                Text("\(value)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Calendar Stats View
struct CalendarStatsView: View {
    let statsData: [DailyStats]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Monthly Overview")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Calendar grid would go here
            Text("Calendar view implementation")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Date Formatters
extension DateFormatter {
    static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    static let dayAbbreviationFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()
}

#Preview {
    StatsView()
        .environmentObject(DataManager())
        .environmentObject(AuthenticationManager())
}
