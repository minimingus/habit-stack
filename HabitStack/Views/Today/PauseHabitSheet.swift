import SwiftUI

struct PauseHabitSheet: View {
    let habitName: String
    let onPause: (Date) -> Void
    @Environment(\.dismiss) private var dismiss

    private let options: [(label: String, days: Int)] = [
        ("1 day",   1),
        ("3 days",  3),
        ("1 week",  7),
        ("2 weeks", 14),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color("Teal"))

                    Text("Pause \"\(habitName)\"")
                        .font(.title3.bold())
                        .multilineTextAlignment(.center)

                    Text("Your streak is protected during the pause.\nWe'll remind you when it ends.")
                        .font(.subheadline)
                        .foregroundStyle(Color("Stone500"))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)

                // Duration options
                VStack(spacing: 12) {
                    ForEach(options, id: \.days) { option in
                        let resumeDate = Calendar.current.date(byAdding: .day, value: option.days, to: Date())!
                        Button {
                            onPause(resumeDate)
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(option.label)
                                        .font(.headline)
                                        .foregroundStyle(Color("Stone950"))
                                    Text("Resumes \(resumeDate.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))")
                                        .font(.caption)
                                        .foregroundStyle(Color("Stone500"))
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundStyle(Color("Stone500"))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(Color("CardBackground"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)

                Spacer()
            }
            .background(Color("AppBackground").ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
