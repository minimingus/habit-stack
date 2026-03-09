import SwiftUI

struct WizardStepCueView: View {
    @Bindable var viewModel: HabitWizardViewModel
    @AppStorage("habitCountAdvisoryDismissed") private var advisoryDismissed = false
    @State private var showTemplateLibrary = false

    private static let defaultCues = [
        "After I wake up",
        "After morning coffee",
        "After lunch",
        "After work",
        "After dinner",
        "Before bed",
    ]

    private var filteredCues: [String] {
        let q = viewModel.cue.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return Self.defaultCues }
        return Self.defaultCues.filter { $0.localizedCaseInsensitiveContains(q) }
    }

    private let colors = ["#0D9488", "#6366F1", "#F59E0B", "#EF4444", "#10B981",
                          "#3B82F6", "#8B5CF6", "#EC4899", "#14B8A6", "#F97316"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                replacementBanner
                habitCountAdvisory

                // Quick Pick — top 8 templates as wrapping chips
                VStack(alignment: .leading, spacing: 10) {
                    Text("Quick Pick")
                        .font(.caption.bold())
                        .foregroundStyle(Color("Stone500"))
                        .textCase(.uppercase)
                        .kerning(0.5)

                    ChipGrid(spacing: 8) {
                        ForEach(HabitTemplateLibrary.all.prefix(8)) { template in
                            SuggestionChip(
                                label: template.name,
                                isSelected: viewModel.name == template.name
                            ) {
                                viewModel.prefill(from: template)
                            }
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: viewModel.name)

                    Button {
                        showTemplateLibrary = true
                    } label: {
                        Text("See all templates →")
                            .font(.caption.bold())
                            .foregroundStyle(Color("Teal"))
                    }
                    .buttonStyle(.plain)
                }

                FormSection(title: "Habit Name") {
                    TextField("e.g. Morning Meditation", text: $viewModel.name)
                        .padding()
                        .background(Color("Stone100"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                FormSection(title: "Color") {
                    HStack(spacing: 10) {
                        ForEach(colors, id: \.self) { color in
                            Button {
                                viewModel.color = color
                            } label: {
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 30, height: 30)
                                    .overlay {
                                        if viewModel.color == color {
                                            Circle().stroke(Color.white, lineWidth: 2)
                                            Circle().stroke(Color(hex: color), lineWidth: 4)
                                        }
                                    }
                            }
                        }
                    }
                }

                FormSection(title: "Cue") {
                    VStack(alignment: .leading, spacing: 10) {
                        if !filteredCues.isEmpty {
                            ChipGrid(spacing: 8) {
                                ForEach(filteredCues, id: \.self) { suggestion in
                                    SuggestionChip(
                                        label: suggestion,
                                        isSelected: viewModel.cue == suggestion
                                    ) {
                                        viewModel.cue = suggestion
                                    }
                                }
                            }
                            .animation(.easeInOut(duration: 0.2), value: filteredCues)
                        }
                        TextField("After I...", text: $viewModel.cue)
                            .padding()
                            .background(Color("Stone100"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }

                if !viewModel.existingHabits.isEmpty {
                    FormSection(title: "Stack After Habit (Optional)") {
                        Picker("Anchor Habit", selection: $viewModel.anchorHabitId) {
                            Text("None").tag(nil as UUID?)
                            ForEach(viewModel.existingHabits.filter { $0.id != viewModel.editingHabitId }) { h in
                                Text("\(h.emoji) \(h.name)").tag(h.id as UUID?)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding()
                        .background(Color("Stone100"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .padding(24)
        }
        .sheet(isPresented: $showTemplateLibrary) {
            HabitTemplateLibraryView(
                onSelect: { template in
                    viewModel.prefill(from: template)
                    showTemplateLibrary = false
                },
                activeHabitNames: Set(viewModel.existingHabits.map { $0.name.lowercased() })
            )
        }
    }

    @ViewBuilder private var replacementBanner: some View {
        if viewModel.replacingBehavior != nil {
            HStack(spacing: 10) {
                Image(systemName: "arrow.triangle.2.circlepath").foregroundStyle(Color("Teal"))
                Text("Same cue, new routine. Keep what triggers it — change what you do.")
                    .font(.subheadline).foregroundStyle(Color("Stone500"))
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("TealLight").opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 24)
        }
    }

    @ViewBuilder private var habitCountAdvisory: some View {
        if !advisoryDismissed && !viewModel.isEditing
            && viewModel.replacingBehavior == nil
            && viewModel.existingHabits.count >= 2 {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb.fill").foregroundStyle(Color("Stone500")).font(.subheadline)
                VStack(alignment: .leading, spacing: 4) {
                    Text("You have \(viewModel.existingHabits.count) habits.")
                        .font(.subheadline.bold())
                    Text("Give each habit a few weeks before adding more.")
                        .font(.caption).foregroundStyle(Color("Stone500"))
                }
                Spacer()
                Button("Got it") { advisoryDismissed = true }
                    .font(.caption.bold()).foregroundStyle(Color("Teal"))
            }
            .padding(12)
            .background(Color("Stone100"))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 24)
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
