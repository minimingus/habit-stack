import SwiftUI

struct HabitGroupView: View {
    let timeOfDay: Habit.TimeOfDay
    let count: Int

    private var routineName: String {
        switch timeOfDay {
        case .morning: return "Morning Routine"
        case .afternoon: return "Afternoon Routine"
        case .evening: return "Evening Routine"
        case .allDay: return "Anytime"
        }
    }

    private var icon: String {
        switch timeOfDay {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "moon.stars.fill"
        case .allDay: return "infinity"
        }
    }

    private var iconColor: Color {
        switch timeOfDay {
        case .morning: return .orange
        case .afternoon: return .yellow
        case .evening: return .indigo
        case .allDay: return Color("Teal")
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.bold())
                .foregroundStyle(iconColor)
            Text(routineName)
                .font(.subheadline.bold())
                .foregroundStyle(Color("Stone950"))
            Spacer()
            Text("\(count) habit\(count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(Color("Stone500"))
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
    }
}
