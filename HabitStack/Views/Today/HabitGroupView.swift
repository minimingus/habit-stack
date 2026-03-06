import SwiftUI

struct HabitGroupView: View {
    let timeOfDay: Habit.TimeOfDay
    let count: Int

    var body: some View {
        HStack {
            Text(timeOfDay.displayName.uppercased())
                .font(.caption.bold())
                .foregroundStyle(Color("Stone500"))
            Spacer()
            Text("\(count)")
                .font(.caption)
                .foregroundStyle(Color("Stone500"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}
