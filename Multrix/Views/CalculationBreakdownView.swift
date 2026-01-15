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
    let onAnimateAllTapped: () -> Void
    let onAnimateRandomTapped: () -> Void
    let isAnimatingSequence: Bool

    // The shared dimension (cols of A = rows of B)
    private var sharedDimension: Int { matrixA.cols }

    private var products: [Int] {
        (0..<sharedDimension).map { k in
            (matrixA.values[resultRow][k] ?? 0) * (matrixB.values[k][resultCol] ?? 0)
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("Result[\(resultRow + 1),\(resultCol + 1)]")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.orange)

            // Show each multiplication
            VStack(alignment: .leading, spacing: 2) {
                ForEach(0..<sharedDimension, id: \.self) { k in
                    let a = matrixA.values[resultRow][k] ?? 0
                    let b = matrixB.values[k][resultCol] ?? 0
                    let product = a * b

                    HStack(spacing: 4) {
                        Text("\(a)")
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                        Text("×")
                            .foregroundColor(.secondary)
                        Text("\(b)")
                            .foregroundColor(.purple)
                            .fontWeight(.medium)
                        Text("=")
                            .foregroundColor(.secondary)
                        Text("\(product)")
                            .fontWeight(.medium)
                    }
                    .font(.system(.callout, design: .rounded))
                }
            }

            Divider()

            // Show the sum
            HStack(spacing: 4) {
                Text(products.map { String($0) }.joined(separator: "+"))
                    .font(.system(.caption2, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text("=")
                Text("\(resultValue)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }

            // Animate buttons
            HStack(spacing: 8) {
                Button(action: onAnimateAllTapped) {
                    Image(systemName: "list.number")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.85))
                        .cornerRadius(6)
                }
                .disabled(isAnimatingSequence)

                Button(action: onAnimateTapped) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                        Text("Animate")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .cornerRadius(6)
                }
                .disabled(isAnimatingSequence)

                Button(action: onAnimateRandomTapped) {
                    Image(systemName: "shuffle")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.85))
                        .cornerRadius(6)
                }
                .disabled(isAnimatingSequence)
            }
            .padding(.top, 4)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.orange.opacity(0.1))
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    CalculationBreakdownView(
        matrixA: Matrix(rows: 2, cols: 3),
        matrixB: Matrix(rows: 3, cols: 2),
        resultRow: 0,
        resultCol: 0,
        resultValue: 100,
        onAnimateTapped: {},
        onAnimateAllTapped: {},
        onAnimateRandomTapped: {},
        isAnimatingSequence: false
    )
}
