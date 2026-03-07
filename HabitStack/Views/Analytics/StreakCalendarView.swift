import SwiftUI

struct StreakCalendarView: View {
    let calendarData: [Date: CalendarDayStatus]

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale.current
        return cal
    }

    private var firstDayOfMonth: Date {
        let comps = calendar.dateComponents([.year, .month], from: Date())
        return calendar.date(from: comps) ?? Date()
    }

    private var weekdayOffset: Int {
        // .weekday returns 1=Sun … 7=Sat; convert to 0-based Sunday start
        (calendar.component(.weekday, from: firstDayOfMonth) - 1)
    }

    private var daysInMonth: Range<Int> {
        calendar.range(of: .day, in: .month, for: Date()) ?? 1..<32
    }

    private var monthHeaderText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: firstDayOfMonth)
    }

    private let dayLabels = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section title
            Text("Monthly Chain")
                .font(.caption.bold())
                .foregroundStyle(Color("Stone500"))
                .textCase(.uppercase)
                .kerning(0.5)

            // Card
            VStack(alignment: .leading, spacing: 12) {
                // Month / year header
                Text(monthHeaderText)
                    .font(.headline)
                    .foregroundStyle(Color.primary)

                // Day-of-week header row
                HStack(spacing: 0) {
                    ForEach(dayLabels, id: \.self) { label in
                        Text(label)
                            .font(.caption)
                            .foregroundStyle(Color("Stone500"))
                            .frame(maxWidth: .infinity)
                    }
                }

                // Day grid
                LazyVGrid(columns: columns, spacing: 6) {
                    // Placeholder offset cells
                    ForEach(0..<weekdayOffset, id: \.self) { _ in
                        Color.clear
                            .frame(width: 34, height: 34)
                    }

                    // Day cells
                    ForEach(daysInMonth, id: \.self) { day in
                        let dayDate = dayDate(for: day)
                        let status = calendarData[dayDate] ?? .empty
                        DayCell(day: day, status: status)
                    }
                }

                // Legend
                HStack(spacing: 16) {
                    LegendSwatch(color: Color("Teal"), label: "Full")
                    LegendSwatch(color: Color("Teal").opacity(0.35), label: "Partial")
                    LegendSwatch(color: Color("Stone100"), label: "None")
                }
            }
            .padding(16)
            .background(Color("CardBackground"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Helpers

    private func dayDate(for day: Int) -> Date {
        var comps = calendar.dateComponents([.year, .month], from: Date())
        comps.day = day
        let date = calendar.date(from: comps) ?? Date()
        return calendar.startOfDay(for: date)
    }
}

// MARK: - DayCell

private struct DayCell: View {
    let day: Int
    let status: CalendarDayStatus

    private var fillColor: Color {
        switch status {
        case .full:    return Color("Teal")
        case .partial: return Color("Teal").opacity(0.35)
        case .empty:   return Color("Stone100")
        }
    }

    private var textColor: Color {
        switch status {
        case .full:             return .white
        case .partial, .empty: return Color("Stone500")
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(fillColor)
                .frame(width: 34, height: 34)

            Text("\(day)")
                .font(.caption)
                .foregroundStyle(textColor)
        }
    }
}

// MARK: - LegendSwatch

private struct LegendSwatch: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color("Stone500"))
        }
    }
}

// MARK: - Preview

#Preview {
    let cal = Calendar.current
    let today = cal.startOfDay(for: Date())
    var sample: [Date: CalendarDayStatus] = [:]
    for offset in 0..<10 {
        if let d = cal.date(byAdding: .day, value: -offset, to: today) {
            sample[d] = offset % 3 == 0 ? .full : offset % 3 == 1 ? .partial : .empty
        }
    }
    return StreakCalendarView(calendarData: sample)
        .padding()
        .background(Color.black)
}
