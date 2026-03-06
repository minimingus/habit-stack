import SwiftUI

struct CoachView: View {
    @State private var viewModel = CoachViewModel()
    @State private var inputText = ""
    @State private var showSuggestions = false
    @FocusState private var isInputFocused: Bool

    private let suggestions = [
        "Why do I keep failing?",
        "Design a morning routine",
        "2-Minute Rule tips"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Always-visible usage bar
                UsageBarView(used: viewModel.messagesUsedToday, limit: viewModel.dailyLimit)

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

                // Collapsible suggestions
                if showSuggestions || viewModel.messages.isEmpty {
                    CoachSuggestionsView(suggestions: suggestions) { suggestion in
                        inputText = suggestion
                        showSuggestions = false
                    }
                }

                // Input bar
                HStack(spacing: 8) {
                    if !viewModel.messages.isEmpty {
                        Button {
                            withAnimation { showSuggestions.toggle() }
                        } label: {
                            Image(systemName: "lightbulb\(showSuggestions ? ".fill" : "")")
                                .foregroundStyle(showSuggestions ? Color("Teal") : Color("Stone500"))
                                .font(.system(size: 20))
                        }
                    }

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
                        showSuggestions = false
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
            .toolbar {
                if !viewModel.messages.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear") {
                            viewModel.clearConversation()
                        }
                        .foregroundStyle(Color("Stone500"))
                        .font(.subheadline)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showPaywall) { PaywallView() }
        }
    }
}

private struct UsageBarView: View {
    let used: Int
    let limit: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.caption)
                .foregroundStyle(Color("Teal"))
            Text("\(used)/\(limit) messages today")
                .font(.caption)
                .foregroundStyle(used >= limit ? .red : Color("Stone500"))
            Spacer()
            if used >= limit - 1 {
                Text("Upgrade for more")
                    .font(.caption.bold())
                    .foregroundStyle(Color("Teal"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(used >= limit ? Color.red.opacity(0.06) : Color("TealLight"))
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
