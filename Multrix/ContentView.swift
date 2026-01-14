//
//  ContentView.swift
//  Multrix
//
//  Created by Mike Schwab on 1/13/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // Dimensions: A is (rowsA × shared), B is (shared × colsB), Result is (rowsA × colsB)
    @State private var rowsA: Int = 4
    @State private var shared: Int = 4
    @State private var colsB: Int = 4

    @State private var matrixA: Matrix
    @State private var matrixB: Matrix
    @State private var result: [[Int]]? = nil
    @State private var showingNumberInput = false
    @State private var editingMatrix: Int = 0  // 0 for A, 1 for B
    @State private var editingRow: Int = 0
    @State private var editingCol: Int = 0
    @State private var selectedResultRow: Int? = nil
    @State private var selectedResultCol: Int? = nil
    @State private var showingDimensionPicker = false

    // Animation state
    @State private var showingAnimation = false
    @State private var animationRunId = UUID()
    @State private var animationSelectedRow: Int? = nil
    @State private var animationSelectedCol: Int? = nil
    @State private var animationResultValue: Int? = nil
    @State private var animationResultCellFrame: CGRect? = nil
    @State private var resultStamps: [ResultCellIdentifier: ResultStamp] = [:]
    @State private var cellPositions: [CellPositionData] = []
    @State private var resultCellPositions: [ResultCellPositionData] = []
    @State private var animationTargetArea: CGRect = .zero

    init() {
        _matrixA = State(initialValue: Matrix(rows: 4, cols: 4))
        _matrixB = State(initialValue: Matrix(rows: 4, cols: 4))
    }

    var body: some View {
        GeometryReader { outerGeo in
            let contentWidth = min(outerGeo.size.width - 32, 560)
            ZStack {
                ScrollView {
                    VStack(spacing: 24) {
                        Text("Matrix Multiplication")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.top)

                        Text("Tap the blue cell in each matrix to enter the missing number")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        // Dimension Picker Toggle
                        Button(action: { showingDimensionPicker.toggle() }) {
                            HStack {
                                Image(systemName: showingDimensionPicker ? "chevron.up" : "chevron.down")
                                Text("Dimensions: A[\(rowsA)×\(shared)] × B[\(shared)×\(colsB)]")
                                Image(systemName: "slider.horizontal.3")
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }

                        if showingDimensionPicker {
                            DimensionPickerView(
                                rowsA: $rowsA,
                                shared: $shared,
                                colsB: $colsB
                            ) {
                                regenerateMatrices()
                                showingDimensionPicker = false
                            }
                            .transition(.scale.combined(with: .opacity))
                        }

                        // Input Matrices
                        if horizontalSizeClass == .regular {
                            // iPad: side by side with animation area
                            HStack(alignment: .center, spacing: 24) {
                                matrixAView
                                Text("×")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                matrixBView

                                // Animation target area (invisible, just for positioning)
                                Color.clear
                                    .frame(width: 200, height: max(CGFloat(shared) * 60, 200))
                                    .background(
                                        GeometryReader { geo in
                                            Color.clear
                                                .onAppear {
                                                    animationTargetArea = geo.frame(in: .named(MatrixCoordinateSpace.name))
                                                }
                                                .onChange(of: geo.frame(in: .named(MatrixCoordinateSpace.name))) { _, newValue in
                                                    animationTargetArea = newValue
                                                }
                                        }
                                    )
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .offset(x: showingAnimation ? -60 : 0)
                        } else {
                            // iPhone: stacked
                            matrixAView
                            Text("×")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            matrixBView

                            // Animation target area below matrices on iPhone
                            if selectedResultRow != nil && selectedResultCol != nil {
                                Color.clear
                                    .frame(height: max(CGFloat(shared) * 60 + 100, 250))
                                    .background(
                                        GeometryReader { geo in
                                            Color.clear
                                                .onAppear {
                                                    animationTargetArea = geo.frame(in: .named(MatrixCoordinateSpace.name))
                                                }
                                                .onChange(of: geo.frame(in: .named(MatrixCoordinateSpace.name))) { _, newValue in
                                                    animationTargetArea = newValue
                                                }
                                        }
                                    )
                            }
                        }

                        // Calculate Button
                        Button(action: calculateResult) {
                            HStack {
                                Image(systemName: "equal")
                                Text("Calculate Result")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: contentWidth)
                            .background(canCalculate ? Color.blue : Color.gray)
                            .cornerRadius(12)
                        }
                        .disabled(!canCalculate)
                        .padding(.horizontal)

                        if !matrixA.isComplete || !matrixB.isComplete {
                            Text("Fill in the missing numbers to calculate")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }

                        // Calculation Breakdown
                        if let result = result,
                           let selectedRow = selectedResultRow,
                           let selectedCol = selectedResultCol {
                            CalculationBreakdownView(
                                matrixA: matrixA,
                                matrixB: matrixB,
                                resultRow: selectedRow,
                                resultCol: selectedCol,
                                resultValue: result[selectedRow][selectedCol],
                                onAnimateTapped: {
                                    animationSelectedRow = selectedRow
                                    animationSelectedCol = selectedCol
                                    animationResultValue = result[selectedRow][selectedCol]
                                    animationResultCellFrame = resultCellPositions.first {
                                        $0.id.row == selectedRow && $0.id.col == selectedCol
                                    }?.frame
                                    animationRunId = UUID()
                                    showingAnimation = true
                                }
                            )
                            .transition(.scale.combined(with: .opacity))
                            .frame(maxWidth: contentWidth)
                        }

                        // Result
                        if let result = result {
                            VStack(spacing: 8) {
                                Text("Result [\(matrixA.rows)×\(matrixB.cols)]")
                                    .font(.headline)
                                Text("Tap a cell to see how it was calculated")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                ResultMatrixView(
                                    values: result,
                                    selectedRow: selectedResultRow,
                                    selectedCol: selectedResultCol
                                ) { row, col in
                                    if selectedResultRow == row && selectedResultCol == col {
                                        // Deselect if tapping same cell
                                        selectedResultRow = nil
                                        selectedResultCol = nil
                                    } else {
                                        selectedResultRow = row
                                        selectedResultCol = col
                                    }
                                }
                            }
                            .transition(.scale.combined(with: .opacity))
                            .frame(maxWidth: contentWidth)
                        }

                        // Reset Button
                        Button(action: reset) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("New Matrices")
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                        .padding(.bottom)
                    }
                    .padding()
                }
                .coordinateSpace(name: MatrixCoordinateSpace.name)
                .onPreferenceChange(CellPositionPreferenceKey.self) { positions in
                    cellPositions = positions
                }
                .onPreferenceChange(ResultCellPositionPreferenceKey.self) { positions in
                    resultCellPositions = positions
                }

                // Animation overlay
                if showingAnimation,
                   let selectedRow = animationSelectedRow,
                   let selectedCol = animationSelectedCol,
                   let finalSum = animationResultValue {
                    MultiplicationAnimationOverlay(
                        cellPositions: cellPositions,
                        targetArea: animationTargetArea,
                        selectedRow: selectedRow,
                        selectedCol: selectedCol,
                        finalSum: finalSum,
                        resultCellFrame: animationResultCellFrame,
                        onResultPlaced: { frame, value in
                            let id = ResultCellIdentifier(row: selectedRow, col: selectedCol)
                            resultStamps[id] = ResultStamp(id: id, frame: frame, value: value)
                        },
                        onAnimationFinished: {
                            showingAnimation = false
                        }
                    )
                    .id(animationRunId)
                    .allowsHitTesting(false)
                }

                ForEach(resultStamps.values.sorted(by: { lhs, rhs in
                    if lhs.id.row != rhs.id.row {
                        return lhs.id.row < rhs.id.row
                    }
                    return lhs.id.col < rhs.id.col
                })) { stamp in
                    resultStampView(stamp)
                        .allowsHitTesting(false)
                }

                // Number input overlay
                if showingNumberInput {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showingNumberInput = false
                        }

                    NumberInputView(isPresented: $showingNumberInput) { number in
                        if editingMatrix == 0 {
                            matrixA.values[editingRow][editingCol] = number
                        } else {
                            matrixB.values[editingRow][editingCol] = number
                        }
                        // Clear result so calculate button becomes active again
                        result = nil
                        selectedResultRow = nil
                        selectedResultCol = nil
                    }
                }
            }
        }
        .animation(.easeInOut, value: result != nil)
        .animation(.easeInOut, value: showingNumberInput)
        .animation(.easeInOut, value: showingDimensionPicker)
        .animation(.easeInOut, value: selectedResultRow)
        .animation(.easeInOut, value: selectedResultCol)
        .animation(.easeInOut, value: showingAnimation)
    }

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
                editingMatrix = 0
                editingRow = row
                editingCol = col
                showingNumberInput = true
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
                editingMatrix = 1
                editingRow = row
                editingCol = col
                showingNumberInput = true
            }
        }
    }

    private var canCalculate: Bool {
        matrixA.isComplete && matrixB.isComplete && result == nil
    }

    private func calculateResult() {
        // Matrix multiplication: C[i][j] = sum(A[i][k] * B[k][j]) for k in 0..<shared
        let resultRows = matrixA.rows
        let resultCols = matrixB.cols
        let sharedDim = matrixA.cols

        var resultMatrix: [[Int]] = Array(repeating: Array(repeating: 0, count: resultCols), count: resultRows)

        for i in 0..<resultRows {
            for j in 0..<resultCols {
                var sum = 0
                for k in 0..<sharedDim {
                    let a = matrixA.values[i][k] ?? 0
                    let b = matrixB.values[k][j] ?? 0
                    sum += a * b
                }
                resultMatrix[i][j] = sum
            }
        }

        result = resultMatrix
    }

    private func regenerateMatrices() {
        matrixA = Matrix(rows: rowsA, cols: shared)
        matrixB = Matrix(rows: shared, cols: colsB)
        result = nil
        selectedResultRow = nil
        selectedResultCol = nil
        resultStamps = [:]
    }

    private func reset() {
        matrixA = Matrix(rows: rowsA, cols: shared)
        matrixB = Matrix(rows: shared, cols: colsB)
        result = nil
        selectedResultRow = nil
        selectedResultCol = nil
        resultStamps = [:]
    }

    private func resultStampView(_ stamp: ResultStamp) -> some View {
        Text("\(stamp.value)")
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .frame(width: 50, height: 50)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.green.opacity(0.9)))
            .scaleEffect(0.9)
            .position(x: stamp.frame.midX, y: stamp.frame.midY)
    }

    private struct ResultStamp: Identifiable {
        let id: ResultCellIdentifier
        let frame: CGRect
        let value: Int
    }
}

#Preview {
    ContentView()
}
