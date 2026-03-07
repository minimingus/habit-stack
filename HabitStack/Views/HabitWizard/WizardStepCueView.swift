import SwiftUI

struct WizardStepCueView: View {
    @Bindable var viewModel: HabitWizardViewModel

    private let colors = ["#0D9488", "#6366F1", "#F59E0B", "#EF4444", "#10B981",
                          "#3B82F6", "#8B5CF6", "#EC4899", "#14B8A6", "#F97316"]

    private let emojis = [
        "✅", "💪", "🏃", "📚", "✍️", "🧘", "💤", "🥗", "💧", "🎯",
        "🌅", "🎵", "📝", "🧠", "❤️", "🌿", "⚡", "🔥", "🎨", "🏋️",
        "🚴", "🏊", "🍎", "☕", "🌙", "📖", "🎓", "💻", "🌞", "🚶",
        "🧹", "🙏", "⏰", "🌬️", "🏆", "⭐", "🧪", "💊", "🎸", "🍵"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
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
                        if !viewModel.suggestedCues.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(viewModel.suggestedCues, id: \.self) { suggestion in
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
                                    Button {
                                        if viewModel.suggestedCues.contains(viewModel.cue) { viewModel.cue = "" }
                                    } label: {
                                        Text("Custom")
                                            .font(.subheadline)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 7)
                                            .background(!viewModel.suggestedCues.contains(viewModel.cue) ? Color("Teal") : Color("Stone100"))
                                            .foregroundStyle(!viewModel.suggestedCues.contains(viewModel.cue) ? .white : Color("Stone950"))
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        if viewModel.suggestedCues.isEmpty || !viewModel.suggestedCues.contains(viewModel.cue) {
                            TextField("After I...", text: $viewModel.cue)
                                .padding()
                                .background(Color("Stone100"))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
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
