//
//  MatrixView.swift
//  Multrix
//
//  Created by Mike Schwab on 1/13/26.
//

import SwiftUI

struct MatrixView: View {
    @Binding var matrix: Matrix
    let matrixIndex: Int  // 0 = A, 1 = B
    var highlightedRow: Int? = nil
    var highlightedCol: Int? = nil
    var animatingCells: Bool = false  // When true, highlighted cells are dimmed
    let onCellTap: (Int, Int) -> Void

    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<matrix.rows, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<matrix.cols, id: \.self) { col in
                        let isHighlighted = (highlightedRow == row) || (highlightedCol == col)
                        let shouldDim = animatingCells && isHighlighted
                        MatrixCellView(
                            value: matrix.values[row][col],
                            isHighlighted: isHighlighted,
                            cellId: CellIdentifier(matrix: matrixIndex, row: row, col: col),
                            dimmed: shouldDim
                        ) {
                            onCellTap(row, col)
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    @Previewable @State var matrix = Matrix(rows: 3, cols: 4)
    VStack {
        MatrixView(matrix: $matrix, matrixIndex: 0, highlightedRow: 1) { row, col in
            print("Tapped \(row), \(col)")
        }
    }
}
