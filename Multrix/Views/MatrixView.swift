//
//  MatrixView.swift
//  Multrix
//
//  Created by Mike Schwab on 1/13/26.
//

import SwiftUI

struct MatrixView: View {
    @Binding var matrix: Matrix
    var highlightedRow: Int? = nil
    var highlightedCol: Int? = nil
    let onCellTap: (Int, Int) -> Void

    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<matrix.rows, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<matrix.cols, id: \.self) { col in
                        let isHighlighted = (highlightedRow == row) || (highlightedCol == col)
                        MatrixCellView(
                            value: matrix.values[row][col],
                            isHighlighted: isHighlighted
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
        MatrixView(matrix: $matrix, highlightedRow: 1) { row, col in
            print("Tapped \(row), \(col)")
        }
    }
}
