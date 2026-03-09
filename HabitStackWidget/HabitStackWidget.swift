import WidgetKit
import SwiftUI

// MARK: - Shared key constants (keep in sync with TodayViewModel)
private let groupSuite = "group.com.tomerab.habitstack"
private let keyCompleted = "widget.completedCount"
private let keyTotal = "widget.totalCount"

// MARK: - Timeline entry

struct HabitProgressEntry: TimelineEntry {
    let date: Date
    let completed: Int
    let total: Int
}

// MARK: - Provider

struct HabitProgressProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitProgressEntry {
        HabitProgressEntry(date: Date(), completed: 3, total: 5)
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitProgressEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitProgressEntry>) -> Void) {
        // Refresh at next midnight so the ring resets each day
        let midnight = Calendar.current.date(
            byAdding: .day, value: 1,
            to: Calendar.current.startOfDay(for: Date())
        ) ?? Date().addingTimeInterval(86400)
        completion(Timeline(entries: [currentEntry()], policy: .after(midnight)))
    }

    private func currentEntry() -> HabitProgressEntry {
        let defaults = UserDefaults(suiteName: groupSuite) ?? .standard
        return HabitProgressEntry(
            date: Date(),
            completed: defaults.integer(forKey: keyCompleted),
            total: defaults.integer(forKey: keyTotal)
        )
    }
}

// MARK: - Widget view

struct HabitProgressWidgetView: View {
    let entry: HabitProgressEntry

    private var progress: Double {
        guard entry.total > 0 else { return 0 }
        return Double(entry.completed) / Double(entry.total)
    }

    // Hardcoded palette to keep widget bundle self-contained
    private let teal     = Color(red: 13/255,  green: 148/255, blue: 136/255)
    private let stone100 = Color(red: 245/255, green: 245/255, blue: 244/255)
    private let stone500 = Color(red: 120/255, green: 113/255, blue: 108/255)
    private let stone950 = Color(red: 28/255,  green: 25/255,  blue: 23/255)
    private let bg       = Color(red: 250/255, green: 250/255, blue: 249/255)

    private var statusText: String {
        if entry.total == 0 { return "No habits" }
        if entry.completed == entry.total { return "All done!" }
        let left = entry.total - entry.completed
        return "\(left) left"
    }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(stone100, lineWidth: 8)

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        teal,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                // Centre count
                VStack(spacing: 1) {
                    Text("\(entry.completed)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(stone950)
                    Text("/ \(entry.total)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(stone500)
                }
            }
            .frame(width: 82, height: 82)

            Text(statusText)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(progress == 1 && entry.total > 0 ? teal : stone500)
        }
        .containerBackground(bg, for: .widget)
    }
}

// MARK: - Widget entry point

@main
struct HabitStackWidget: Widget {
    let kind = "HabitProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitProgressProvider()) { entry in
            HabitProgressWidgetView(entry: entry)
        }
        .configurationDisplayName("Daily Progress")
        .description("See how many habits you've completed today.")
        .supportedFamilies([.systemSmall])
    }
}
