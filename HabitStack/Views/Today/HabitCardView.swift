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
    @State private var showDetail = false
    @State private var showNote = false
    @State private var showTimer = false
    @State private var showFrictionSheet = false
    @State private var durationMinutes: Int = 0
    @State private var isQuantified: Bool = false
    @State private var targetCount: Int = 0
    @State private var currentCount: Int = 0

    private var habit: Habit { habitWithStatus.habit }
    private var durationKey: String { "habitDuration_\(habit.id.uuidString)" }
    private var accentColor: Color { Color(hex: habit.color) }
    private var todayCountKey: String {
        let date = String(ISO8601DateFormatter().string(from: Date()).prefix(10))
        return "habitCount_\(habit.id.uuidString)_\(date)"
    }

    private var hasFriction: Bool {
        !habit.reminderEnabled && (habit.tinyVersion ?? "").isEmpty
    }

    var body: some View {
        HStack(spacing: 14) {

            // MARK: Complete Button (Binary or Quantified)
            if isQuantified && targetCount > 0 {
                quantifiedButton
            } else {
                HoldCompleteButton(
                    isCompleted: habitWithStatus.isCompleted,
                    accentColor: accentColor,
                    onComplete: {
                        onToggle()
                        withAnimation { showConfetti = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showConfetti = false
                        }
                    },
                    onUncomplete: {
                        onToggle()
                    }
                )
            }

            // MARK: Habit Info (tappable → detail)
            Button { showDetail = true } label: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(accentColor)
                                .frame(width: 40, height: 40)
                            Text(String(habit.name.prefix(1)).uppercased())
                                .font(.headline.bold())
                                .foregroundStyle(.white)
                        }
                        Text(habit.name)
                            .font(.headline)
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

                    if hasFriction {
                        Button { showFrictionSheet = true } label: {
                            Text("Needs setup")
                                .font(.caption.bold())
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.orange.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            // MARK: Right side — Timer + Streak + Rating
            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 8) {
                    // Timer button (timed habits only)
                    if durationMinutes > 0 && !habitWithStatus.isCompleted {
                        Button { showTimer = true } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "timer")
                                Text("\(durationMinutes)m")
                            }
                            .font(.caption.bold())
                            .foregroundStyle(Color("Teal"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color("TealLight"))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    if let streak, streak.currentStreak > 0 {
                        StreakBadge(streak: streak.currentStreak)
                    }
                }

                if habitWithStatus.isCompleted {
                    Button { showNote = true } label: {
                        Image(systemName: "pencil.circle")
                            .font(.title3)
                            .foregroundStyle(Color("Stone500").opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: habitWithStatus.isCompleted)
                }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
        .background(
            habitWithStatus.isCompleted
                ? accentColor.opacity(0.07)
                : Color("CardBackground")
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.07), lineWidth: 0.5)
        )
        .animation(.easeInOut(duration: 0.25), value: habitWithStatus.isCompleted)
        .overlay(alignment: .top) {
            if showConfetti {
                ConfettiView()
                    .frame(height: 120)
                    .offset(y: -40)
                    .allowsHitTesting(false)
            }
        }
        .contextMenu {
            Button { onEdit() } label: { Label("Edit Habit", systemImage: "pencil") }
            Button(role: .destructive) { showArchiveAlert = true } label: { Label("Archive", systemImage: "archivebox") }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button(action: onEdit) { Label("Edit", systemImage: "pencil") }.tint(Color("Teal"))
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button { showArchiveAlert = true } label: { Label("Archive", systemImage: "archivebox") }.tint(.orange)
        }
        .alert("Archive Habit?", isPresented: $showArchiveAlert) {
            Button("Archive", role: .destructive, action: onArchive)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This habit will be archived and removed from your daily view.")
        }
        .sheet(isPresented: $showDetail) {
            HabitDetailView(habit: habit, streak: streak, anchorName: anchorName, onEdit: onEdit, onArchive: onArchive)
        }
        .sheet(isPresented: $showNote) {
            CompletionNoteSheet(habitName: habit.name, habitId: habit.id, onDismiss: {})
        }
        .sheet(isPresented: $showTimer) {
            HabitTimerView(
                habitName: habit.name,
                habitEmoji: habit.emoji,
                durationMinutes: durationMinutes,
                onComplete: {
                    onToggle()
                }
            )
        }
        .sheet(isPresented: $showFrictionSheet) {
            HabitFrictionSheet(habit: habit, onSave: {
                // card will reflect changes on next loadToday
            })
        }
        .onAppear {
            durationMinutes = UserDefaults.standard.integer(forKey: durationKey)
            isQuantified = UserDefaults.standard.bool(forKey: "habitQuantified_\(habit.id.uuidString)")
            let savedTarget = UserDefaults.standard.integer(forKey: "habitTargetCount_\(habit.id.uuidString)")
            if savedTarget > 0 { targetCount = savedTarget }
            currentCount = UserDefaults.standard.integer(forKey: todayCountKey)
        }
    }

    // MARK: - Quantified Habit Button

    @ViewBuilder
    private var quantifiedButton: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color("Stone100"), lineWidth: 3)
                    .frame(width: 56, height: 56)

                Circle()
                    .trim(from: 0, to: min(1.0, Double(currentCount) / Double(targetCount)))
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 56, height: 56)
                    .animation(.easeInOut(duration: 0.2), value: currentCount)

                if habitWithStatus.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.title3.bold())
                        .foregroundStyle(accentColor)
                } else {
                    VStack(spacing: 0) {
                        Text("\(currentCount)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color("Stone950"))
                        Text("/\(targetCount)")
                            .font(.system(size: 10))
                            .foregroundStyle(Color("Stone500"))
                    }
                }
            }

            HStack(spacing: 14) {
                Button {
                    guard currentCount > 0 else { return }
                    currentCount -= 1
                    UserDefaults.standard.set(currentCount, forKey: todayCountKey)
                    if currentCount < targetCount && habitWithStatus.isCompleted {
                        onToggle()
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.caption.bold())
                        .foregroundStyle(Color("Stone500"))
                }
                .disabled(currentCount == 0)

                Button {
                    guard currentCount < targetCount else { return }
                    currentCount += 1
                    UserDefaults.standard.set(currentCount, forKey: todayCountKey)
                    HapticManager.impact(.light)
                    if currentCount >= targetCount && !habitWithStatus.isCompleted {
                        onToggle()
                        withAnimation { showConfetti = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { showConfetti = false }
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.caption.bold())
                        .foregroundStyle(accentColor)
                }
                .disabled(currentCount >= targetCount)
            }
        }
    }

}
