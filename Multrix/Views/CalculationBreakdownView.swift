//
//  CalculationBreakdownView.swift
//  Multrix
//
//  Created by Mike Schwab on 1/13/26.
//

import SwiftUI

struct CalculationBreakdownView: View {
    let matrixA: Matrix
    let matrixB: Matrix
    let resultRow: Int
    let resultCol: Int
    let resultValue: Int
    let onAnimateTapped: () -> Void

    // The shared dimension (cols of A = rows of B)
    private var sharedDimension: Int { matrixA.cols }

    private var products: [Int] {
        (0..<sharedDimension).map { k in
            (matrixA.values[resultRow][k] ?? 0) * (matrixB.values[k][resultCol] ?? 0)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Calculation for Result[\(resultRow + 1),\(resultCol + 1)]")
                .font(.headline)
                .foregroundColor(.orange)

            // Show the formula
            VStack(spacing: 8) {
                Text("Row \(resultRow + 1) of A × Column \(resultCol + 1) of B")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Show each multiplication
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(0..<sharedDimension, id: \.self) { k in
                        let a = matrixA.values[resultRow][k] ?? 0
                        let b = matrixB.values[k][resultCol] ?? 0
                        let product = a * b

                        HStack {
                            Text("\(a)")
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                            Text("×")
                            Text("\(b)")
                                .foregroundColor(.purple)
                                .fontWeight(.medium)
                            Text("=")
                            Text("\(product)")
                                .fontWeight(.medium)
                        }
                        .font(.system(.body, design: .monospaced))
                    }
                }

                Divider()

                // Show the sum
                HStack {
                    Text(products.map { String($0) }.joined(separator: " + "))
                        .font(.system(.caption, design: .monospaced))
                    Text("=")
                    Text("\(resultValue)")
                        .font(.headline)
                        .foregroundColor(.green)
                }

                // Animate button
                Button(action: onAnimateTapped) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Animate")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.orange)
                    .cornerRadius(8)
                }
                .padding(.top, 8)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.1))
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

#Preview {
    CalculationBreakdownView(
        matrixA: Matrix(rows: 2, cols: 3),
        matrixB: Matrix(rows: 3, cols: 2),
        resultRow: 0,
        resultCol: 0,
        resultValue: 100,
        onAnimateTapped: {}
    )
}
