import SwiftUI

/// A wrapping chip layout — chips fill left-to-right then wrap to the next row.
/// Eliminates horizontal scrolling for short-to-medium chip lists.
struct ChipGrid: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(maxWidth: proposal.width ?? 0, subviews: subviews)
        guard !rows.isEmpty else { return .zero }
        let height = rows.map { rowHeight($0, subviews: subviews) }.reduce(0, +)
            + CGFloat(rows.count - 1) * spacing
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(maxWidth: bounds.width, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let h = rowHeight(row, subviews: subviews)
            for index in row {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y + (h - size.height) / 2), proposal: .unspecified)
                x += size.width + spacing
            }
            y += h + spacing
        }
    }

    // MARK: - Private

    private func computeRows(maxWidth: CGFloat, subviews: Subviews) -> [[Int]] {
        var rows: [[Int]] = [[]]
        var currentWidth: CGFloat = 0
        for (i, subview) in subviews.enumerated() {
            let w = subview.sizeThatFits(.unspecified).width
            if currentWidth + w > maxWidth, !rows[rows.count - 1].isEmpty {
                rows.append([i])
                currentWidth = w + spacing
            } else {
                rows[rows.count - 1].append(i)
                currentWidth += w + spacing
            }
        }
        return rows
    }

    private func rowHeight(_ row: [Int], subviews: Subviews) -> CGFloat {
        row.map { subviews[$0].sizeThatFits(.unspecified).height }.max() ?? 0
    }
}

/// A single suggestion chip. Selected chips use Teal fill; unselected use a card background.
struct SuggestionChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption2.bold())
                }
                Text(label)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                isSelected ? Color("Teal") : Color("CardBackground")
            )
            .foregroundStyle(isSelected ? Color.white : Color("Stone950"))
            .clipShape(Capsule())
            .shadow(
                color: isSelected ? Color.clear : Color.black.opacity(0.07),
                radius: 3, x: 0, y: 1
            )
            .overlay(
                Capsule().strokeBorder(
                    isSelected ? Color.clear : Color.white.opacity(0.08),
                    lineWidth: 0.5
                )
            )
        }
        .buttonStyle(.plain)
    }
}
