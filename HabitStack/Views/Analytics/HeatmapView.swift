import SwiftUI

struct HeatmapView: View {
    let cells: [(date: Date, status: HabitLog.Status?)]
    let onTap: ((date: Date, status: HabitLog.Status?)) -> Void

    private let columns = 7
    private let cellSize: CGFloat = 36
    private let spacing: CGFloat = 4

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity")
                .font(.headline)

            Canvas { context, size in
                let totalWidth = size.width
                let cellWithSpacing = totalWidth / CGFloat(columns)
                let actualCell = cellWithSpacing - spacing

                for (index, cell) in cells.enumerated() {
                    let col = index % columns
                    let row = index / columns
                    let x = CGFloat(col) * cellWithSpacing
                    let y = CGFloat(row) * (actualCell + spacing)
                    let rect = CGRect(x: x, y: y, width: actualCell, height: actualCell)
                    let path = Path(roundedRect: rect, cornerRadius: 6)

                    let color: Color = switch cell.status {
                    case .done: Color("Teal")
                    case .skipped: Color("TealLight")
                    default: Color("Stone100")
                    }
                    context.fill(path, with: .color(color))
                }
            }
            .frame(height: CGFloat(cells.count / columns) * (cellSize + spacing))
            .gesture(
                SpatialTapGesture()
                    .onEnded { value in
                        let totalWidth = UIScreen.main.bounds.width - 32
                        let cellWithSpacing = totalWidth / CGFloat(columns)
                        let actualCell = cellWithSpacing - spacing
                        let col = Int(value.location.x / cellWithSpacing)
                        let row = Int(value.location.y / (actualCell + spacing))
                        let index = row * columns + col
                        if index >= 0 && index < cells.count {
                            onTap(cells[index])
                        }
                    }
            )
        }
    }
}

struct CellDetailView: View {
    let date: Date
    let status: HabitLog.Status?

    var body: some View {
        VStack(spacing: 16) {
            Text(date.formatted(date: .complete, time: .omitted))
                .font(.headline)
            if let status {
                Text(status.rawValue.capitalized)
                    .foregroundStyle(status == .done ? Color("Teal") : Color("Stone500"))
            } else {
                Text("No log for this day")
                    .foregroundStyle(Color("Stone500"))
            }
        }
        .padding()
    }
}
