import SwiftUI

struct AdminSpendView: View {
    @State private var usageRecords: [CoachUsageRecord] = []
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss

    struct CoachUsageRecord: Codable, Identifiable {
        let id: UUID
        let model: String
        let inputTokens: Int
        let outputTokens: Int
        let createdAt: Date

        enum CodingKeys: String, CodingKey {
            case id, model
            case inputTokens = "input_tokens"
            case outputTokens = "output_tokens"
            case createdAt = "created_at"
        }

        var estimatedCost: Double {
            // claude-haiku: $0.25/M input, $1.25/M output
            // claude-sonnet: $3/M input, $15/M output
            let (inputRate, outputRate): (Double, Double) = model.contains("haiku")
                ? (0.00000025, 0.00000125)
                : (0.000003, 0.000015)
            return Double(inputTokens) * inputRate + Double(outputTokens) * outputRate
        }
    }

    var totalCost: Double { usageRecords.reduce(0) { $0 + $1.estimatedCost } }

    var body: some View {
        NavigationStack {
            List {
                Section("Summary") {
                    LabeledContent("Total Records") { Text("\(usageRecords.count)") }
                    LabeledContent("Estimated Cost") { Text(String(format: "$%.4f", totalCost)) }
                }

                Section("Recent Usage") {
                    ForEach(usageRecords.prefix(20)) { record in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.model)
                                .font(.caption.bold())
                            HStack {
                                Text("In: \(record.inputTokens)")
                                    .font(.caption)
                                Text("Out: \(record.outputTokens)")
                                    .font(.caption)
                                Spacer()
                                Text(String(format: "$%.5f", record.estimatedCost))
                                    .font(.caption)
                                    .foregroundStyle(Color("Stone500"))
                            }
                        }
                    }
                }
            }
            .navigationTitle("API Spend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await loadUsage() }
        }
    }

    private func loadUsage() async {
        guard let userId = try? await supabase.auth.session.user.id else { return }
        isLoading = true
        usageRecords = (try? await supabase
            .from("coach_usage")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value) ?? []
        isLoading = false
    }
}
