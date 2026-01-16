//
//  ResultSectionView.swift
//  Multrix
//

import SwiftUI

struct ResultSectionView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let result: [[Int]]
    let matrixA: Matrix
    let matrixB: Matrix
    let selectedRow: Int?
    let selectedCol: Int?
    let isAnimatingSequence: Bool
    let contentWidth: CGFloat
    let onCellSelected: (_ row: Int?, _ col: Int?) -> Void
    let onAnimateTapped: () -> Void
    let onAnimateAllTapped: () -> Void
    let onAnimateRandomTapped: () -> Void

    var body: some View {
        if horizontalSizeClass == .regular {
            iPadLayout
        } else {
            iPhoneLayout
        }
    }

    // MARK: - Layouts

    private var iPadLayout: some View {
        HStack(alignment: .top, spacing: 24) {
            if let row = selectedRow, let col = selectedCol {
                calculationBreakdown(row: row, col: col)
                    .frame(maxWidth: 280)
            }

            resultMatrixSection
        }
        .transition(.scale.combined(with: .opacity))
    }

    private var iPhoneLayout: some View {
        VStack(spacing: 16) {
            if let row = selectedRow, let col = selectedCol {
                calculationBreakdown(row: row, col: col)
                    .transition(.scale.combined(with: .opacity))
                    .frame(maxWidth: contentWidth)
            }

            resultMatrixSection
                .transition(.scale.combined(with: .opacity))
                .frame(maxWidth: contentWidth)
        }
    }

    // MARK: - Subviews

    private func calculationBreakdown(row: Int, col: Int) -> some View {
        CalculationBreakdownView(
            matrixA: matrixA,
            matrixB: matrixB,
            resultRow: row,
            resultCol: col,
            resultValue: result[row][col],
            onAnimateTapped: onAnimateTapped,
            onAnimateAllTapped: onAnimateAllTapped,
            onAnimateRandomTapped: onAnimateRandomTapped,
            isAnimatingSequence: isAnimatingSequence
        )
    }

    private var resultMatrixSection: some View {
        VStack(spacing: 8) {
            Text("Result [\(matrixA.rows)×\(matrixB.cols)]")
                .font(.headline)
                .accessibilityIdentifier("result.title")
            Text("Tap a cell to see how it was calculated")
                .font(.caption)
                .foregroundColor(.secondary)
                .accessibilityIdentifier("result.hint")
            ResultMatrixView(
                values: result,
                selectedRow: selectedRow,
                selectedCol: selectedCol
            ) { row, col in
                if selectedRow == row && selectedCol == col {
                    onCellSelected(nil, nil)
                } else {
                    onCellSelected(row, col)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("result.matrix")
    }
}

// MARK: - Previews

private let previewMatrixA = Matrix(rows: 2, cols: 2)
private let previewMatrixB = Matrix(rows: 2, cols: 2)
private let previewResult = [[10, 20], [30, 40]]

#Preview("iPad - Cell Selected") {
    ResultSectionView(
        result: previewResult,
        matrixA: previewMatrixA,
        matrixB: previewMatrixB,
        selectedRow: 0,
        selectedCol: 0,
        isAnimatingSequence: false,
        contentWidth: 500,
        onCellSelected: { _, _ in },
        onAnimateTapped: {},
        onAnimateAllTapped: {},
        onAnimateRandomTapped: {}
    )
    .environment(\.horizontalSizeClass, .regular)
    .padding()
}

#Preview("iPad - No Selection") {
    ResultSectionView(
        result: previewResult,
        matrixA: previewMatrixA,
        matrixB: previewMatrixB,
        selectedRow: nil,
        selectedCol: nil,
        isAnimatingSequence: false,
        contentWidth: 500,
        onCellSelected: { _, _ in },
        onAnimateTapped: {},
        onAnimateAllTapped: {},
        onAnimateRandomTapped: {}
    )
    .environment(\.horizontalSizeClass, .regular)
    .padding()
}

#Preview("iPhone - Cell Selected") {
    ResultSectionView(
        result: previewResult,
        matrixA: previewMatrixA,
        matrixB: previewMatrixB,
        selectedRow: 1,
        selectedCol: 1,
        isAnimatingSequence: false,
        contentWidth: 350,
        onCellSelected: { _, _ in },
        onAnimateTapped: {},
        onAnimateAllTapped: {},
        onAnimateRandomTapped: {}
    )
    .environment(\.horizontalSizeClass, .compact)
    .padding()
}

#Preview("Animating") {
    ResultSectionView(
        result: previewResult,
        matrixA: previewMatrixA,
        matrixB: previewMatrixB,
        selectedRow: 0,
        selectedCol: 1,
        isAnimatingSequence: true,
        contentWidth: 500,
        onCellSelected: { _, _ in },
        onAnimateTapped: {},
        onAnimateAllTapped: {},
        onAnimateRandomTapped: {}
    )
    .environment(\.horizontalSizeClass, .regular)
    .padding()
}
