import SwiftUI
import PostHog

/// Issue #23 + #4 — Identity-filtered swipeable habit suggestions with quick-add after adopt.
struct AddHabitSwipeView: View {
    let onAdded: () -> Void

    @State private var templates: [HabitTemplate] = []
    @State private var currentIndex = 0
    @State private var pendingTemplate: HabitTemplate?
    @State private var showTimePicker = false
    @State private var showWizard = false
    @State private var selectedTime: Habit.TimeOfDay = .morning
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var allDone = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if allDone || templates.isEmpty {
                    emptyState
                } else {
                    cardStack
                    actionHints
                }

                Spacer()

                Button {
                    showWizard = true
                } label: {
                    Text("Build a custom habit instead")
                        .font(.subheadline)
                        .foregroundStyle(Color("Stone500"))
                        .padding(.vertical, 16)
                }
            }
            .navigationTitle("Add a Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task { loadTemplates() }
            .sheet(isPresented: $showTimePicker) {
                if let template = pendingTemplate {
                    TimePickerSheet(template: template, selectedTime: $selectedTime) {
                        Task { await adoptHabit(template, time: selectedTime) }
                    }
                    .presentationDetents([.medium])
                }
            }
            .sheet(isPresented: $showWizard) {
                HabitWizardView {
                    onAdded()
                    dismiss()
                }
            }
            .alert("Couldn't add habit", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
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
                            pendingTemplate = templates[index]
                            selectedTime = templates[index].defaultTime
                            showTimePicker = true
                        }
                    )
                    .scaleEffect(1.0 - Double(offset) * 0.04)
                    .offset(y: Double(offset) * 10)
                    .zIndex(Double(3 - offset))
                    .disabled(offset != 0)
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
            Text("\(max(0, templates.count - currentIndex)) left")
                .font(.caption)
                .foregroundStyle(Color("Stone500"))
            Spacer()
            Label("Add", systemImage: "checkmark")
                .font(.subheadline)
                .foregroundStyle(Color("Teal"))
        }
        .padding(.horizontal, 48)
        .padding(.top, 8)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color("Teal"))
            Text("You've reviewed all suggestions")
                .font(.title3.bold())
            Text("Build a custom habit below, or come back later for new ideas.")
                .font(.subheadline)
                .foregroundStyle(Color("Stone500"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.top, 60)
    }

    // MARK: - Logic

    private func loadTemplates() {
        // Read identity traits persisted during onboarding
        let raw = UserDefaults.standard.stringArray(forKey: "selectedIdentityTraits") ?? []
        let traits = raw.compactMap { IdentityTrait(rawValue: $0) }

        // Load existing habit names to exclude already-adopted ones
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

            let filtered = HabitTemplateLibrary.filtered(by: traits)
                .filter { !existingNames.contains($0.name.lowercased()) }

            await MainActor.run {
                self.templates = filtered
            }
        }
    }

    private func skip() {
        withAnimation { currentIndex += 1 }
        if currentIndex >= templates.count { allDone = true }
    }

    private func adoptHabit(_ template: HabitTemplate, time: Habit.TimeOfDay) async {
        isSaving = true
        defer { isSaving = false }
        do {
            guard let userId = try? await supabase.auth.session.user.id else { return }
            let count: [Habit] = (try? await supabase
                .from("habits")
                .select("id")
                .eq("user_id", value: userId.uuidString)
                .is("archived_at", value: nil)
                .execute()
                .value) ?? []
            let habit = Habit(
                id: UUID(),
                userId: userId,
                name: template.name,
                emoji: template.emoji,
                color: "#0D9488",
                frequency: .daily,
                timeOfDay: time,
                reminderEnabled: false,
                difficultyLevel: 1,
                sortOrder: count.count,
                createdAt: Date()
            )
            let isPro = RevenueCatManager.shared.isProUser
            try await HabitService.shared.createHabit(habit, isPro: isPro)
            PostHogSDK.shared.capture("habit_adopted_from_suggestions", properties: [
                "habit_name": template.name,
                "category": template.category.rawValue
            ])
            await MainActor.run {
                showTimePicker = false
                currentIndex += 1
                if currentIndex >= templates.count { allDone = true }
                onAdded()
            }
        } catch HabitServiceError.freeTierHabitLimit {
            await MainActor.run {
                showTimePicker = false
                errorMessage = "You've reached the free tier limit of 5 habits. Upgrade to Pro for unlimited habits."
            }
        } catch {
            await MainActor.run {
                showTimePicker = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Time Picker Sheet

private struct TimePickerSheet: View {
    let template: HabitTemplate
    @Binding var selectedTime: Habit.TimeOfDay
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text(template.emoji)
                    .font(.system(size: 48))
                Text("When will you \(template.name.lowercased())?")
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 24)

            Picker("Time of Day", selection: $selectedTime) {
                ForEach(Habit.TimeOfDay.allCases, id: \.self) { tod in
                    Text(tod.displayName).tag(tod)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 120)
            .clipped()

            Button {
                onConfirm()
            } label: {
                Text("Add Habit")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("Teal"))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)

            Button("Cancel") { dismiss() }
                .foregroundStyle(Color("Stone500"))

            Spacer()
        }
    }
}
