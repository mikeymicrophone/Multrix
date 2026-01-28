//
//  ResultMatrixView.swift
//  Multrix
//
//  Created by Mike Schwab on 1/13/26.
//

import SwiftUI

struct ResultMatrixView: View {
    let values: [[Int]]
    let selectedRow: Int?
    let selectedCol: Int?
    let changedCells: Set<ResultCellIdentifier>
    let onCellTap: (Int, Int) -> Void

    private var rows: Int { values.count }
    private var cols: Int { values.first?.count ?? 0 }

    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<cols, id: \.self) { col in
                        let isSelected = row == selectedRow && col == selectedCol
                        let isChanged = changedCells.contains(ResultCellIdentifier(row: row, col: col))
                        Button {
                            onCellTap(row, col)
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(fillColor(isSelected: isSelected, isChanged: isChanged))
                                    .stroke(strokeColor(isSelected: isSelected, isChanged: isChanged), lineWidth: isSelected ? 2 : 1)

                                Text("\(values[row][col])")
                                    .font(.system(size: 14))
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                                    .foregroundColor(isSelected ? .orange : (isChanged ? .red : .primary))
                            }
                            .frame(width: 50, height: 50)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("result.cell.\(row).\(col)")
                        .accessibilityLabel("Result cell \(row + 1) \(col + 1)")
                        .accessibilityValue("\(values[row][col])")
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(
                                    key: ResultCellPositionPreferenceKey.self,
                                    value: [
                                        ResultCellPositionData(
                                            id: ResultCellIdentifier(row: row, col: col),
                                            frame: geo.frame(in: .named(MatrixCoordinateSpace.name))
                                        )
                                    ]
                                )
                            }
                        )
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.5), lineWidth: 2)
        )
        .accessibilityElement(children: .contain)
    }

    private func fillColor(isSelected: Bool, isChanged: Bool) -> Color {
        if isSelected {
            return Color.orange.opacity(0.3)
        }
        if isChanged {
            return Color.red.opacity(0.2)
        }
        return Color.green.opacity(0.1)
    }

    private func strokeColor(isSelected: Bool, isChanged: Bool) -> Color {
        if isSelected {
            return Color.orange
        }
        if isChanged {
            return Color.red.opacity(0.7)
        }
        return Color.green.opacity(0.3)
    }
}

#Preview {
    ResultMatrixView(
        values: [
            [10, 20, 30],
            [50, 60, 70]
        ],
        selectedRow: 1,
        selectedCol: 2,
        changedCells: [ResultCellIdentifier(row: 0, col: 1)],
        onCellTap: { _, _ in }
    )
}
