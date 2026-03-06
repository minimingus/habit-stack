import SwiftUI

struct HabitCardView: View {
    let habitWithStatus: HabitWithStatus
    let streak: Streak?
    let anchorName: String?
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onArchive: () -> Void

    @State private var showArchiveAlert = false
    @State private var showConfetti = false
    @State private var wasCompleted = false

    private var habit: Habit { habitWithStatus.habit }

    var body: some View {
        HStack(spacing: 12) {
            CheckButton(isCompleted: habitWithStatus.isCompleted, onTap: {
                let wasAlreadyDone = habitWithStatus.isCompleted
                onToggle()
                if !wasAlreadyDone {
                    withAnimation { showConfetti = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showConfetti = false
                    }
                }
            })

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(habit.emoji)
                    Text(habit.name)
                        .font(.body)
                        .foregroundStyle(Color("Stone950"))
                }

                if let anchorName {
                    Text("↳ After \(anchorName)")
                        .font(.caption)
                        .foregroundStyle(Color("Stone500"))
                }

                if let tiny = habit.tinyVersion, !tiny.isEmpty {
                    Text(tiny)
                        .font(.caption)
                        .foregroundStyle(Color("Stone500"))
                }
            }

            Spacer()

            if let streak, streak.currentStreak > 0 {
                StreakBadge(streak: streak.currentStreak)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        .overlay(alignment: .top) {
            if showConfetti {
                ConfettiView()
                    .frame(height: 120)
                    .offset(y: -40)
                    .allowsHitTesting(false)
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            .tint(Color("Teal"))
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                showArchiveAlert = true
            } label: {
                Label("Archive", systemImage: "archivebox")
            }
            .tint(.orange)
        }
        .alert("Archive Habit?", isPresented: $showArchiveAlert) {
            Button("Archive", role: .destructive, action: onArchive)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This habit will be archived and removed from your daily view.")
        }
    }
}
