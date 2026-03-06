import SwiftUI

struct CoachView: View {
    @State private var viewModel = CoachViewModel()
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool

    private let suggestions = [
        "Why do I keep failing?",
        "Design a morning routine",
        "2-Minute Rule tips"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Rate limit banner
                if viewModel.messagesRemainingToday <= 2 {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(Color("Teal"))
                        Text("\(viewModel.messagesRemainingToday) of 5 messages remaining today")
                            .font(.caption)
                            .foregroundStyle(Color("Stone500"))
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(Color("TealLight"))
                }

                ScrollViewReader { proxy in
                    ScrollView {
                        if viewModel.messages.isEmpty {
                            EmptyStateView(
                                icon: "bubble.left.and.bubble.right",
                                headline: "Ask your Habit Coach",
                                subtext: "Get personalized advice based on Atomic Habits methodology."
                            )
                            .frame(minHeight: 300)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.messages) { message in
                                    CoachMessageView(message: message)
                                }
                                if viewModel.isLoading {
                                    TypingIndicatorView()
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .onChange(of: viewModel.messages.count) {
                        withAnimation { proxy.scrollTo("bottom") }
                    }
                    .onChange(of: viewModel.isLoading) {
                        withAnimation { proxy.scrollTo("bottom") }
                    }
                }

                Divider()

                // Suggestions
                if viewModel.messages.isEmpty {
                    CoachSuggestionsView(suggestions: suggestions) { suggestion in
                        inputText = suggestion
                    }
                }

                // Input bar
                HStack(spacing: 12) {
                    TextField("Ask anything...", text: $inputText, axis: .vertical)
                        .lineLimit(1...4)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color("Stone100"))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .focused($isInputFocused)

                    Button {
                        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !text.isEmpty else { return }
                        inputText = ""
                        Task { await viewModel.sendMessage(text) }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(inputText.isEmpty ? Color("Stone500") : Color("Teal"))
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .navigationTitle("AI Coach")
            .sheet(isPresented: $viewModel.showPaywall) { PaywallView() }
        }
    }
}

struct TypingIndicatorView: View {
    @State private var phase = 0
    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(alignment: .bottom) {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color("Stone500"))
                        .frame(width: 6, height: 6)
                        .offset(y: phase == i ? -4 : 0)
                        .animation(.easeInOut(duration: 0.3), value: phase)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
            Spacer()
        }
        .onReceive(timer) { _ in phase = (phase + 1) % 3 }
    }
}
