import SwiftUI

struct HabitTemplateLibraryView: View {
    let onSelect: (HabitTemplate) -> Void
    var activeHabitNames: Set<String> = []
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: HabitCategory? = nil

    private func isActive(_ template: HabitTemplate) -> Bool {
        activeHabitNames.contains(template.name.lowercased())
    }

    private var filteredTemplates: [HabitTemplate] {
        let base = selectedCategory.map { HabitTemplateLibrary.templates(for: $0) } ?? HabitTemplateLibrary.all
        return base.filter { !isActive($0) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // MARK: Starter Packs
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Quick Start")
                            .font(.caption.bold())
                            .foregroundStyle(Color("Stone500"))
                            .textCase(.uppercase)
                            .kerning(0.5)
                            .padding(.horizontal, 16)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(HabitTemplateLibrary.starterPacks) { pack in
                                    let available = pack.templates.filter { !isActive($0) }
                                    if !available.isEmpty {
                                        StarterPackCard(pack: pack) {
                                            if let first = available.first {
                                                onSelect(first)
                                                dismiss()
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }

                    // MARK: Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryChip(label: "All", icon: "square.grid.2x2", isSelected: selectedCategory == nil) {
                                selectedCategory = nil
                            }
                            ForEach(HabitCategory.allCases) { category in
                                CategoryChip(
                                    label: category.rawValue,
                                    icon: category.icon,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // MARK: Templates
                    VStack(spacing: 1) {
                        ForEach(Array(filteredTemplates.enumerated()), id: \.element.id) { index, template in
                            TemplateRow(template: template) {
                                onSelect(template)
                                dismiss()
                            }
                            if index < filteredTemplates.count - 1 {
                                Divider().padding(.leading, 56)
                            }
                        }
                    }
                    .background(Color("CardBackground"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 16)
            }
            .background(Color("AppBackground").ignoresSafeArea())
            .navigationTitle("Habit Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Starter Pack Card

private struct StarterPackCard: View {
    let pack: StarterPack
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: pack.icon)
                    .font(.title2)
                    .foregroundStyle(Color("Teal"))

                Text(pack.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color("Stone950"))

                VStack(alignment: .leading, spacing: 2) {
                    ForEach(pack.templates.prefix(3)) { template in
                        Text("· \(template.name)")
                            .font(.caption)
                            .foregroundStyle(Color("Stone500"))
                    }
                }
            }
            .padding(14)
            .frame(width: 160, alignment: .leading)
            .background(Color("CardBackground"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Chip

private struct CategoryChip: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption)
                Text(label)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? Color("Teal") : Color("CardBackground"))
            .foregroundStyle(isSelected ? Color.white : Color("Stone950"))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(isSelected ? 0 : 0.05), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Template Row

private struct TemplateRow: View {
    let template: HabitTemplate
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(template.emoji)
                    .font(.title3)
                    .frame(width: 36, height: 36)
                    .background(Color("TealLight"))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 3) {
                    Text(template.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color("Stone950"))
                    Text("Tiny: \(template.tinyVersion)")
                        .font(.caption)
                        .foregroundStyle(Color("Stone500"))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(Color("Stone500"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}
