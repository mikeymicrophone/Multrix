//
//  MatrixView.swift
//  Multrix
//
//  Created by Mike Schwab on 1/13/26.
//

import SwiftUI

struct MatrixView: View {
    @Binding var matrix: Matrix
    let onCellTap: (Int, Int) -> Void

    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<4, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<4, id: \.self) { col in
                        MatrixCellView(
                            value: matrix.values[row][col],
                            isEditable: row == matrix.missingRow && col == matrix.missingCol
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
    @Previewable @State var matrix = Matrix()
    MatrixView(matrix: $matrix) { row, col in
        print("Tapped \(row), \(col)")
    }
}
