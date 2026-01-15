//
//  InputMatricesSectionView.swift
//  Multrix
//

import SwiftUI

struct InputMatricesSectionView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Binding var matrixA: Matrix
    @Binding var matrixB: Matrix
    let selectedResultRow: Int?
    let selectedResultCol: Int?
    let sharedDimension: Int
    let onCellTapped: (_ matrix: Int, _ row: Int, _ col: Int) -> Void
    let onAnimationAreaChanged: (CGRect) -> Void

    var body: some View {
        if horizontalSizeClass == .regular {
            iPadLayout
        } else {
            iPhoneLayout
        }
    }

    // MARK: - Layouts

    private var iPadLayout: some View {
        HStack(alignment: .center, spacing: 24) {
            matrixAView
            multiplicationSymbol
            matrixBView
            animationTargetArea
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var iPhoneLayout: some View {
        VStack(spacing: 16) {
            matrixAView
            multiplicationSymbol
            matrixBView

            if selectedResultRow != nil && selectedResultCol != nil {
                animationTargetAreaPhone
            }
        }
    }

    // MARK: - Subviews

    private var matrixAView: some View {
        VStack(spacing: 8) {
            Text("Matrix A [\(matrixA.rows)×\(matrixA.cols)]")
                .font(.headline)
            MatrixView(
                matrix: $matrixA,
                matrixIndex: 0,
                highlightedRow: selectedResultRow,
                animatingCells: false
            ) { row, col in
                onCellTapped(0, row, col)
            }
        }
    }

    private var matrixBView: some View {
        VStack(spacing: 8) {
            Text("Matrix B [\(matrixB.rows)×\(matrixB.cols)]")
                .font(.headline)
            MatrixView(
                matrix: $matrixB,
                matrixIndex: 1,
                highlightedCol: selectedResultCol,
                animatingCells: false
            ) { row, col in
                onCellTapped(1, row, col)
            }
        }
    }

    private var multiplicationSymbol: some View {
        Text("×")
            .font(.largeTitle)
            .fontWeight(.bold)
    }

    private var animationTargetArea: some View {
        Color.clear
            .frame(width: 200, height: max(CGFloat(sharedDimension) * 60, 200))
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            onAnimationAreaChanged(geo.frame(in: .named(MatrixCoordinateSpace.name)))
                        }
                        .onChange(of: geo.frame(in: .named(MatrixCoordinateSpace.name))) { _, newValue in
                            onAnimationAreaChanged(newValue)
                        }
                }
            )
    }

    private var animationTargetAreaPhone: some View {
        Color.clear
            .frame(height: max(CGFloat(sharedDimension) * 60 + 100, 250))
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            onAnimationAreaChanged(geo.frame(in: .named(MatrixCoordinateSpace.name)))
                        }
                        .onChange(of: geo.frame(in: .named(MatrixCoordinateSpace.name))) { _, newValue in
                            onAnimationAreaChanged(newValue)
                        }
                }
            )
    }
}

// MARK: - Previews

#Preview("iPad Layout") {
    InputMatricesSectionView(
        matrixA: .constant(Matrix(rows: 2, cols: 3)),
        matrixB: .constant(Matrix(rows: 3, cols: 2)),
        selectedResultRow: 0,
        selectedResultCol: 1,
        sharedDimension: 3,
        onCellTapped: { _, _, _ in },
        onAnimationAreaChanged: { _ in }
    )
    .environment(\.horizontalSizeClass, .regular)
    .padding()
}

#Preview("iPhone Layout") {
    InputMatricesSectionView(
        matrixA: .constant(Matrix(rows: 2, cols: 2)),
        matrixB: .constant(Matrix(rows: 2, cols: 2)),
        selectedResultRow: nil,
        selectedResultCol: nil,
        sharedDimension: 2,
        onCellTapped: { _, _, _ in },
        onAnimationAreaChanged: { _ in }
    )
    .environment(\.horizontalSizeClass, .compact)
    .padding()
}

#Preview("Large Matrices") {
    InputMatricesSectionView(
        matrixA: .constant(Matrix(rows: 4, cols: 4)),
        matrixB: .constant(Matrix(rows: 4, cols: 4)),
        selectedResultRow: 2,
        selectedResultCol: 3,
        sharedDimension: 4,
        onCellTapped: { _, _, _ in },
        onAnimationAreaChanged: { _ in }
    )
    .environment(\.horizontalSizeClass, .regular)
    .padding()
}
