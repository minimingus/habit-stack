import SwiftUI

struct IdentityStatementView: View {
    @Binding var statement: String
    let onContinue: () -> Void
    let onSkip: () -> Void

    @FocusState private var isFocused: Bool

    private let suggestions = [
        "reads every day",
        "exercises consistently",
        "sleeps 8 hours",
        "eats healthy",
        "meditates daily",
        "journals regularly",
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Skip", action: onSkip)
                    .foregroundStyle(Color("Stone500"))
                    .padding()
            }

            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 12) {
                        Image(systemName: "person.fill.checkmark")
                            .font(.system(size: 52))
                            .foregroundStyle(Color("Teal"))

                        Text("Who are you becoming?")
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)

                        Text("Every habit is a vote for the person you're becoming.")
                            .font(.body)
                            .foregroundStyle(Color("Stone500"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    .padding(.top, 16)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("I am someone who…")
                            .font(.caption.bold())
                            .foregroundStyle(Color("Stone500"))
                            .textCase(.uppercase)
                            .kerning(0.5)

                        TextField("e.g. exercises consistently", text: $statement)
                            .focused($isFocused)
                            .padding(14)
                            .background(Color("Stone100"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .submitLabel(.done)
                            .onSubmit {
                                if !statement.trimmingCharacters(in: .whitespaces).isEmpty {
                                    onContinue()
                                }
                            }
                    }
                    .padding(.horizontal, 24)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Or pick one to start")
                            .font(.caption)
                            .foregroundStyle(Color("Stone500"))
                            .padding(.horizontal, 24)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(suggestions, id: \.self) { suggestion in
                                    Button {
                                        statement = suggestion
                                        isFocused = false
                                    } label: {
                                        Text(suggestion)
                                            .font(.subheadline)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(
                                                statement == suggestion
                                                    ? Color("Teal")
                                                    : Color("Stone100")
                                            )
                                            .foregroundStyle(
                                                statement == suggestion
                                                    ? Color.white
                                                    : Color("Stone950")
                                            )
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                }
                .padding(.bottom, 40)
            }

            VStack(spacing: 12) {
                Button(action: onContinue) {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            statement.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color("Stone100")
                                : Color("Teal")
                        )
                        .foregroundStyle(
                            statement.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color("Stone500")
                                : Color.white
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(statement.trimmingCharacters(in: .whitespaces).isEmpty)
                .animation(.easeInOut(duration: 0.15), value: statement.isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .background(.regularMaterial)
        }
        .onAppear { isFocused = true }
    }
}
