import WidgetKit
import SwiftUI

// MARK: - Shared Data Manager for Widget
class WidgetDataManager {
    static let shared = WidgetDataManager()
    private let appGroupID = "group.com.macrotrackr.shared"
    
    private init() {}
    
    func loadTodaysData() -> (macros: MacroNutrition, goals: MacroGoals)? {
        guard let sharedContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            return nil
        }
        
        let macrosURL = sharedContainer.appendingPathComponent("today_macros.json")
        let goalsURL = sharedContainer.appendingPathComponent("user_goals.json")
        
        do {
            let macrosData = try Data(contentsOf: macrosURL)
            let goalsData = try Data(contentsOf: goalsURL)
            
            let macros = try JSONDecoder().decode(MacroNutrition.self, from: macrosData)
            let goals = try JSONDecoder().decode(MacroGoals.self, from: goalsData)
            
            return (macros, goals)
        } catch {
            print("Widget: Failed to load shared data: \(error)")
            return nil
        }
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> MacroEntry {
        createEntry(with: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (MacroEntry) -> ()) {
        let entry = createEntry(with: WidgetDataManager.shared.loadTodaysData())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [MacroEntry] = []
        
        // Load current data
        let currentData = WidgetDataManager.shared.loadTodaysData()
        
        // Generate entries for the next few hours
        let currentDate = Date()
        for hourOffset in 0 ..< 6 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = createEntry(with: currentData, date: entryDate)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    private func createEntry(with data: (macros: MacroNutrition, goals: MacroGoals)?, date: Date = Date()) -> MacroEntry {
        let macros: MacroNutrition
        let goals: MacroGoals
        
        if let data = data {
            macros = data.macros
            goals = data.goals
        } else {
            // When no data is available, show zeros to reflect actual user progress
            macros = MacroNutrition(calories: 0, protein: 0, carbohydrates: 0, fat: 0, sugar: 0, fiber: 0)
            goals = MacroGoals() // Keep default goals
        }
        
        // Calculate progress percentages
        let progress = MacroProgress(
            caloriesProgress: goals.calories > 0 ? (macros.calories / goals.calories) * 100 : 0,
            proteinProgress: goals.protein > 0 ? (macros.protein / goals.protein) * 100 : 0,
            carbohydratesProgress: goals.carbohydrates > 0 ? (macros.carbohydrates / goals.carbohydrates) * 100 : 0,
            fatProgress: goals.fat > 0 ? (macros.fat / goals.fat) * 100 : 0,
            sugarProgress: goals.sugar > 0 ? (macros.sugar / goals.sugar) * 100 : 0,
            fiberProgress: goals.fiber > 0 ? (macros.fiber / goals.fiber) * 100 : 0
        )
        
        return MacroEntry(
            date: date,
            totalMacros: macros,
            goals: goals,
            progress: progress
        )
    }
}

struct MacroEntry: TimelineEntry {
    let date: Date
    let totalMacros: MacroNutrition
    let goals: MacroGoals
    let progress: MacroProgress
}

struct MacroTrackrWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget View
struct SmallWidgetView: View {
    let entry: MacroEntry
    
    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("Today")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(entry.progress.caloriesProgress))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }
            
            // Progress Circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                
                Circle()
                    .trim(from: 0, to: entry.progress.caloriesProgress / 100)
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 2) {
                    Text("\(Int(entry.totalMacros.calories))")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("kcal")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 60, height: 60)
            
            // Remaining calories
            Text("\(Int(entry.goals.calories - entry.totalMacros.calories)) left")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - Medium Widget View
struct MediumWidgetView: View {
    let entry: MacroEntry
    
    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("MacroTrackr")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(DateFormatter.widgetDateFormatter.string(from: entry.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Macro Progress Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 6) {
                MacroWidgetCard(
                    title: "Calories",
                    current: Int(entry.totalMacros.calories),
                    goal: Int(entry.goals.calories),
                    progress: entry.progress.caloriesProgress,
                    color: .orange
                )
                
                MacroWidgetCard(
                    title: "Protein",
                    current: Int(entry.totalMacros.protein),
                    goal: Int(entry.goals.protein),
                    progress: entry.progress.proteinProgress,
                    color: .red
                )
                
                MacroWidgetCard(
                    title: "Carbs",
                    current: Int(entry.totalMacros.carbohydrates),
                    goal: Int(entry.goals.carbohydrates),
                    progress: entry.progress.carbohydratesProgress,
                    color: .blue
                )
                
                MacroWidgetCard(
                    title: "Fat",
                    current: Int(entry.totalMacros.fat),
                    goal: Int(entry.goals.fat),
                    progress: entry.progress.fatProgress,
                    color: .green
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - Large Widget View
struct LargeWidgetView: View {
    let entry: MacroEntry
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("MacroTrackr")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(DateFormatter.widgetDateFormatter.string(from: entry.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(entry.progress.caloriesProgress))% Complete")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
            }
            
            // All Macros
            VStack(spacing: 8) {
                MacroWidgetRow(
                    title: "Calories",
                    current: Int(entry.totalMacros.calories),
                    goal: Int(entry.goals.calories),
                    progress: entry.progress.caloriesProgress,
                    color: .orange,
                    unit: "kcal"
                )
                
                MacroWidgetRow(
                    title: "Protein",
                    current: Int(entry.totalMacros.protein),
                    goal: Int(entry.goals.protein),
                    progress: entry.progress.proteinProgress,
                    color: .red,
                    unit: "g"
                )
                
                MacroWidgetRow(
                    title: "Carbohydrates",
                    current: Int(entry.totalMacros.carbohydrates),
                    goal: Int(entry.goals.carbohydrates),
                    progress: entry.progress.carbohydratesProgress,
                    color: .blue,
                    unit: "g"
                )
                
                MacroWidgetRow(
                    title: "Fat",
                    current: Int(entry.totalMacros.fat),
                    goal: Int(entry.goals.fat),
                    progress: entry.progress.fatProgress,
                    color: .green,
                    unit: "g"
                )
                
                MacroWidgetRow(
                    title: "Sugar",
                    current: Int(entry.totalMacros.sugar),
                    goal: Int(entry.goals.sugar),
                    progress: entry.progress.sugarProgress,
                    color: .pink,
                    unit: "g"
                )
                
                MacroWidgetRow(
                    title: "Fiber",
                    current: Int(entry.totalMacros.fiber),
                    goal: Int(entry.goals.fiber),
                    progress: entry.progress.fiberProgress,
                    color: .brown,
                    unit: "g"
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - Widget Components
struct MacroWidgetCard: View {
    let title: String
    let current: Int
    let goal: Int
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(current)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text("/\(goal)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress / 100)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(x: 1, y: 1.5, anchor: .center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct MacroWidgetRow: View {
    let title: String
    let current: Int
    let goal: Int
    let progress: Double
    let color: Color
    let unit: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
                .frame(width: 80, alignment: .leading)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(current)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text("/\(goal) \(unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 80, alignment: .trailing)
            
            ProgressView(value: progress / 100)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            Text("\(Int(progress))%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

struct MacroTrackrWidget: Widget {
    let kind: String = "MacroTrackrWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MacroTrackrWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("MacroTrackr")
        .description("Track your daily macro progress on your home screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Date Formatter
extension DateFormatter {
    static let widgetDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
}

#Preview(as: .systemSmall) {
    MacroTrackrWidget()
} timeline: {
    MacroEntry(
        date: Date(),
        totalMacros: MacroNutrition(calories: 1200, protein: 80, carbohydrates: 120, fat: 45, sugar: 30, fiber: 15),
        goals: MacroGoals(),
        progress: MacroProgress(caloriesProgress: 60, proteinProgress: 53, carbohydratesProgress: 48, fatProgress: 69, sugarProgress: 60, fiberProgress: 60)
    )
}

#Preview(as: .systemMedium) {
    MacroTrackrWidget()
} timeline: {
    MacroEntry(
        date: Date(),
        totalMacros: MacroNutrition(calories: 1200, protein: 80, carbohydrates: 120, fat: 45, sugar: 30, fiber: 15),
        goals: MacroGoals(),
        progress: MacroProgress(caloriesProgress: 60, proteinProgress: 53, carbohydratesProgress: 48, fatProgress: 69, sugarProgress: 60, fiberProgress: 60)
    )
}

#Preview(as: .systemLarge) {
    MacroTrackrWidget()
} timeline: {
    MacroEntry(
        date: Date(),
        totalMacros: MacroNutrition(calories: 1200, protein: 80, carbohydrates: 120, fat: 45, sugar: 30, fiber: 15),
        goals: MacroGoals(),
        progress: MacroProgress(caloriesProgress: 60, proteinProgress: 53, carbohydratesProgress: 48, fatProgress: 69, sugarProgress: 60, fiberProgress: 60)
    )
}
