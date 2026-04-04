import WidgetKit
import SwiftUI

// MARK: - Shared key constants (keep in sync with TodayViewModel)
private let groupSuite = "group.com.tomerab.better"
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

// MARK: - Clay palette (self-contained, no asset catalog access from widget)

private let clay     = Color(red: 194/255, green: 103/255, blue: 58/255)
private let clayLight = Color(red: 1.0,    green: 245/255, blue: 240/255)
private let stone100 = Color(red: 245/255, green: 237/255, blue: 229/255)
private let stone500 = Color(red: 168/255, green: 144/255, blue: 128/255)
private let stone950 = Color(red: 28/255,  green: 25/255,  blue: 23/255)
private let bg       = Color(red: 250/255, green: 248/255, blue: 245/255)

// MARK: - Small widget view

struct HabitProgressSmallView: View {
    let entry: HabitProgressEntry

    private var progress: Double {
        guard entry.total > 0 else { return 0 }
        return Double(entry.completed) / Double(entry.total)
    }

    private var statusText: String {
        if entry.total == 0 { return "No habits" }
        if entry.completed == entry.total { return "All done! 🎉" }
        let left = entry.total - entry.completed
        return "\(left) left"
    }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(stone100, lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(clay, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
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
                .foregroundStyle(progress == 1 && entry.total > 0 ? clay : stone500)
        }
    }
}

// MARK: - Medium widget view

struct HabitProgressMediumView: View {
    let entry: HabitProgressEntry

    private var progress: Double {
        guard entry.total > 0 else { return 0 }
        return Double(entry.completed) / Double(entry.total)
    }

    var body: some View {
        HStack(spacing: 20) {
            // Left: ring
            ZStack {
                Circle()
                    .stroke(stone100, lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(clay, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 1) {
                    Text("\(entry.completed)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(stone950)
                    Text("/ \(entry.total)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(stone500)
                }
            }
            .frame(width: 80, height: 80)

            // Right: text summary
            VStack(alignment: .leading, spacing: 6) {
                Text("Today")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(stone950)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(stone100)
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(clay)
                            .frame(width: geo.size.width * progress, height: 4)
                    }
                }
                .frame(height: 4)

                Text(summaryText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(stone500)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 4)
    }

    private var summaryText: String {
        if entry.total == 0 { return "Add habits to get started" }
        if entry.completed == entry.total { return "All \(entry.total) habits done! 🎉" }
        let left = entry.total - entry.completed
        return "\(left) habit\(left == 1 ? "" : "s") remaining"
    }
}

// MARK: - Unified widget view

struct HabitProgressWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: HabitProgressEntry

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                HabitProgressMediumView(entry: entry)
            default:
                HabitProgressSmallView(entry: entry)
            }
        }
        .widgetURL(URL(string: "better://quick-complete"))
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
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
