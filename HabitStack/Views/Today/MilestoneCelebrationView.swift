import SwiftUI

struct MilestoneCelebrationView: View {
    let streakDays: Int
    let habitName: String
    let onDismiss: () -> Void

    @State private var showShareSheet = false
    @State private var shareUIImage: UIImage?

    private var milestoneName: String {
        switch streakDays {
        case 0: return "Perfect Day"
        case 7: return "One Week In"
        case 14: return "Showing Up Daily"
        case 21: return "Habit Forming"
        case 30: return "One Month of Showing Up"
        case 66: return "Automatic"
        case 100: return "100 Days of Consistency"
        default: return "\(streakDays) Days of Showing Up"
        }
    }

    private var milestoneMessage: String {
        switch streakDays {
        case 0: return "Every habit. Every day. That's consistency."
        case 7: return "Seven days of showing up. Consistency beats motivation every time."
        case 14: return "Two weeks of daily practice. The habit is taking root."
        case 21: return "Three weeks of showing up. Consistency is becoming your default."
        case 30: return "One month of daily action. This is who you are now."
        case 66: return "66 days. Showing up has become automatic."
        case 100: return "100 days of consistency. Not a streak — a lifestyle."
        default: return "Consistent action compounds. Keep showing up."
        }
    }

    private var milestoneEmoji: String {
        switch streakDays {
        case 0: return "⭐"
        case 7: return "🔥"
        case 14: return "⚡"
        case 21: return "🌱"
        case 30: return "🏆"
        case 66: return "🧠"
        case 100: return "💯"
        default: return "⭐"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text(milestoneEmoji)
                .font(.system(size: 80))
                .padding(.bottom, 20)

            VStack(spacing: 10) {
                Text(milestoneName)
                    .font(.title.bold())
                    .foregroundStyle(Color("Stone950"))

                if streakDays > 0 {
                    Text("\(streakDays) days of \(habitName)")
                        .font(.subheadline)
                        .foregroundStyle(Color("Stone500"))
                }
            }

            Text(milestoneMessage)
                .font(.body)
                .foregroundStyle(Color("Stone500"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 24)

            Spacer()

            VStack(spacing: 12) {
                Button(action: onDismiss) {
                    Text("Keep Going")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color("Teal"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    renderShareCard()
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color("Teal"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color("TealLight"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("AppBackground").ignoresSafeArea())
        .presentationDetents([.large])
        .sheet(isPresented: $showShareSheet) {
            if let img = shareUIImage {
                ShareSheet(items: [img])
            }
        }
    }

    @MainActor
    private func renderShareCard() {
        let card = StreakShareCard(
            streakDays: streakDays,
            habitName: habitName,
            milestoneName: milestoneName,
            milestoneEmoji: milestoneEmoji
        )
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0
        shareUIImage = renderer.uiImage
        showShareSheet = true
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
