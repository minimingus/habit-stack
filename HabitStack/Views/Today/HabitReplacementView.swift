import SwiftUI
import PostHog

/// Issue #24 — Swap an existing habit for a template suggestion in the same time slot.
struct HabitReplacementView: View {
    let habit: Habit
    let onReplaced: () -> Void

    @State private var templates: [HabitTemplate] = []
    @State private var currentIndex = 0
    @State private var allDone = false
    @State private var isSwapping = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                replacingBanner

                if allDone || templates.isEmpty {
                    emptyState
                } else {
                    cardStack
                    actionHints
                }

                Spacer()
            }
            .navigationTitle("Replace Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task { loadTemplates() }
            .alert("Couldn't replace habit", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Replacing Banner

    private var replacingBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.left.arrow.right")
                .foregroundStyle(Color("Teal"))
            Text("Replacing \"\(habit.name)\" — swipe right to swap")
                .font(.subheadline)
                .foregroundStyle(Color("Stone500"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color("TealLight"))
    }

    // MARK: - Card Stack

    private var cardStack: some View {
        ZStack {
            ForEach(stackIndices, id: \.self) { offset in
                let index = currentIndex + offset
                guard index < templates.count else { return AnyView(EmptyView()) }
                return AnyView(
                    SwipeableHabitCard(
                        template: templates[index],
                        onSwipeLeft: { skip() },
                        onSwipeRight: {
                            Task { await swap(to: templates[index]) }
                        }
                    )
                    .scaleEffect(1.0 - Double(offset) * 0.04)
                    .offset(y: Double(offset) * 10)
                    .zIndex(Double(3 - offset))
                    .disabled(offset != 0 || isSwapping)
                )
            }
        }
        .frame(height: 500)
        .padding(.top, 16)
    }

    private var stackIndices: [Int] {
        let remaining = templates.count - currentIndex
        return Array(0..<min(3, remaining))
    }

    // MARK: - Action Hints

    private var actionHints: some View {
        HStack {
            Label("Skip", systemImage: "xmark")
                .font(.subheadline)
                .foregroundStyle(Color("Stone500"))
            Spacer()
            Text("\(max(0, templates.count - currentIndex)) suggestions")
                .font(.caption)
                .foregroundStyle(Color("Stone500"))
            Spacer()
            Label("Swap", systemImage: "arrow.left.arrow.right")
                .font(.subheadline)
                .foregroundStyle(Color("Teal"))
        }
        .padding(.horizontal, 48)
        .padding(.top, 8)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color("Stone500"))
            Text("No suggestions for this time slot")
                .font(.title3.bold())
            Text("All templates for \(habit.timeOfDay.displayName.lowercased()) are already in your habits.")
                .font(.subheadline)
                .foregroundStyle(Color("Stone500"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.top, 60)
    }

    // MARK: - Logic

    private func loadTemplates() {
        Task {
            let existingNames: Set<String>
            if let userId = try? await supabase.auth.session.user.id {
                let existing: [Habit] = (try? await supabase
                    .from("habits")
                    .select("name")
                    .eq("user_id", value: userId.uuidString)
                    .is("archived_at", value: nil)
                    .execute()
                    .value) ?? []
                existingNames = Set(existing.map { $0.name.lowercased() })
            } else {
                existingNames = []
            }

            // Suggest templates for the same time of day, excluding current habit and already-adopted ones
            let suggestions = HabitTemplateLibrary.all
                .filter { $0.defaultTime == habit.timeOfDay }
                .filter { !existingNames.contains($0.name.lowercased()) }

            await MainActor.run {
                self.templates = suggestions
            }
        }
    }

    private func skip() {
        withAnimation { currentIndex += 1 }
        if currentIndex >= templates.count { allDone = true }
    }

    private func swap(to template: HabitTemplate) async {
        isSwapping = true
        defer { isSwapping = false }
        do {
            guard let userId = try? await supabase.auth.session.user.id else { return }

            // Archive the old habit
            try await HabitService.shared.archiveHabit(habit.id)

            // Create the new habit, inheriting the same time slot and cue
            let count: [Habit] = (try? await supabase
                .from("habits")
                .select("id")
                .eq("user_id", value: userId.uuidString)
                .is("archived_at", value: nil)
                .execute()
                .value) ?? []
            let newHabit = Habit(
                id: UUID(),
                userId: userId,
                name: template.name,
                emoji: template.emoji,
                color: habit.color,
                cue: habit.cue,
                frequency: habit.frequency,
                timeOfDay: habit.timeOfDay,
                reminderEnabled: habit.reminderEnabled,
                reminderTime: habit.reminderTime,
                difficultyLevel: 1,
                sortOrder: count.count,
                createdAt: Date()
            )
            let isPro = RevenueCatManager.shared.isProUser
            try await HabitService.shared.createHabit(newHabit, isPro: isPro)

            PostHogSDK.shared.capture("habit_replaced", properties: [
                "old_habit": habit.name,
                "new_habit": template.name,
                "time_of_day": habit.timeOfDay.rawValue
            ])

            await MainActor.run {
                onReplaced()
                dismiss()
            }
        } catch HabitServiceError.freeTierHabitLimit {
            await MainActor.run {
                errorMessage = "You've reached the free tier limit of 5 habits. Upgrade to Pro for unlimited habits."
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
}
