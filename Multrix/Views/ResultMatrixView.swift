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
    let onCellTap: (Int, Int) -> Void

    private var rows: Int { values.count }
    private var cols: Int { values.first?.count ?? 0 }

    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<cols, id: \.self) { col in
                        let isSelected = row == selectedRow && col == selectedCol
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isSelected ? Color.orange.opacity(0.3) : Color.green.opacity(0.1))
                                .stroke(isSelected ? Color.orange : Color.green.opacity(0.3), lineWidth: isSelected ? 2 : 1)

                            Text("\(values[row][col])")
                                .font(.system(size: 14))
                                .fontWeight(.medium)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                        .frame(width: 50, height: 50)
                        .onTapGesture {
                            onCellTap(row, col)
                        }
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
        onCellTap: { _, _ in }
    )
}
