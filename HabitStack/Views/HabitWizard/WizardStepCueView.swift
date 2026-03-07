import SwiftUI

struct WizardStepCueView: View {
    @Bindable var viewModel: HabitWizardViewModel
    @AppStorage("habitCountAdvisoryDismissed") private var advisoryDismissed = false

    private static let defaultCues = [
        "After I wake up",
        "After morning coffee",
        "After lunch",
        "After work",
        "After dinner",
        "Before bed",
    ]

    private let colors = ["#0D9488", "#6366F1", "#F59E0B", "#EF4444", "#10B981",
                          "#3B82F6", "#8B5CF6", "#EC4899", "#14B8A6", "#F97316"]

    private let emojis = [
        "✅", "💪", "🏃", "📚", "✍️", "🧘", "💤", "🥗", "💧", "🎯",
        "🌅", "🎵", "📝", "🧠", "❤️", "🌿", "⚡", "🔥", "🎨", "🤸",
        "🚴", "🏊", "🍎", "☕", "🌙", "📖", "🎓", "💻", "🌞", "🚶",
        "🧹", "🙏", "⏰", "🌊", "🏆", "⭐", "🫁", "💊", "🎸", "🍵"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                replacementBanner
                habitCountAdvisory

                // Quick Pick — suggests templates inline
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Pick")
                        .font(.caption.bold())
                        .foregroundStyle(Color("Stone500"))
                        .textCase(.uppercase)
                        .kerning(0.5)
                        .padding(.horizontal, 24)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(HabitTemplateLibrary.all) { template in
                                Button {
                                    viewModel.prefill(from: template)
                                } label: {
                                    HStack(spacing: 5) {
                                        Text(template.emoji)
                                        Text(template.name)
                                            .font(.subheadline)
                                            .foregroundStyle(Color("Stone950"))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(
                                        viewModel.name == template.name
                                            ? Color("TealLight")
                                            : Color("Stone100")
                                    )
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().strokeBorder(
                                            viewModel.name == template.name
                                                ? Color("Teal")
                                                : Color.clear,
                                            lineWidth: 1.5
                                        )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }

                FormSection(title: "Habit Name") {
                    TextField("e.g. Morning Meditation", text: $viewModel.name)
                        .padding()
                        .background(Color("Stone100"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                FormSection(title: "Emoji") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                        ForEach(emojis, id: \.self) { emoji in
                            Button {
                                viewModel.emoji = emoji
                            } label: {
                                Text(emoji)
                                    .font(.title3)
                                    .frame(width: 36, height: 36)
                                    .background(viewModel.emoji == emoji ? Color("TealLight") : Color("Stone100"))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay {
                                        if viewModel.emoji == emoji {
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color("Teal"), lineWidth: 2)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
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
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Self.defaultCues, id: \.self) { suggestion in
                                    Button {
                                        viewModel.cue = suggestion
                                    } label: {
                                        Text(suggestion)
                                            .font(.subheadline)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 7)
                                            .background(viewModel.cue == suggestion ? Color("Teal") : Color("Stone100"))
                                            .foregroundStyle(viewModel.cue == suggestion ? .white : Color("Stone950"))
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
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
