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

    // Animation state
    @State private var showingAnimation = false
    @State private var animationRunId = UUID()
    @State private var animationSelectedRow: Int? = nil
    @State private var animationSelectedCol: Int? = nil
    @State private var animationResultValue: Int? = nil
    @State private var animationResultCellFrame: CGRect? = nil
    @State private var resultStamps: [ResultCellIdentifier: Int] = [:]
    @State private var isAnimatingSequence = false
    @State private var isSequencePaused = false
    @State private var animationSpeed: AnimationSpeed = .normal
    @State private var additionMode: AdditionMode = .collapse
    @State private var numberComplexity: NumberComplexity = .moderate
    @State private var showingPreferences = false
    @State private var sequenceTask: Task<Void, Never>? = nil
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
                        HStack {
                            Spacer()
                            Button(action: { showingPreferences = true }) {
                                Image(systemName: "gearshape")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                                    .padding(8)
                            }
                            .accessibilityLabel("Preferences")
                        }

                        Text("Matrix Multiplication")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.top)

                        Text("Tap the blue cell in each matrix to enter the missing number")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

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

                        HStack(spacing: 16) {
                            Button(action: {
                                isSequencePaused.toggle()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: isSequencePaused ? "play.fill" : "pause.fill")
                                    Text(isSequencePaused ? "Resume" : "Pause")
                                }
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(isAnimatingSequence ? Color.orange : Color.gray.opacity(0.4))
                                .cornerRadius(8)
                            }
                            .disabled(!isAnimatingSequence)
                        }
                        .frame(maxWidth: contentWidth, alignment: .leading)

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
                                },
                                onAnimateAllTapped: {
                                    startSequentialAnimation()
                                },
                                onAnimateRandomTapped: {
                                    startRandomAnimation()
                                },
                                isAnimatingSequence: isAnimatingSequence || result == nil
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
                .scrollDisabled(showingAnimation || isAnimatingSequence)
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
                        speed: animationSpeed,
                        additionMode: additionMode,
                        isPaused: $isSequencePaused,
                        onResultPlaced: { frame, value in
                            let id = ResultCellIdentifier(row: selectedRow, col: selectedCol)
                            resultStamps[id] = value
                        },
                        onAnimationFinished: {
                            // Only hide animation if not in a sequence
                            // During sequences, we keep showingAnimation true and change the ID
                            if !isAnimatingSequence {
                                showingAnimation = false
                            }
                        }
                    )
                    .id(animationRunId)
                    .allowsHitTesting(false)
                }

                ForEach(sortedResultStampIds, id: \.self) { id in
                    if let frame = resultCellFrame(for: id), let value = resultStamps[id] {
                        resultStampView(id: id, frame: frame, value: value)
                            .allowsHitTesting(false)
                    }
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
        .animation(.easeInOut, value: selectedResultRow)
        .animation(.easeInOut, value: selectedResultCol)
        .animation(.easeInOut, value: showingAnimation)
        .sheet(isPresented: $showingPreferences) {
            NavigationStack {
                Form {
                    Section("Matrix Dimensions") {
                        DimensionPickerView(
                            rowsA: $rowsA,
                            shared: $shared,
                            colsB: $colsB
                        ) {
                            regenerateMatrices()
                        }
                    }

                    Section {
                        Picker("Complexity", selection: $numberComplexity) {
                            ForEach(NumberComplexity.allCases, id: \.self) { complexity in
                                Text(complexity.title).tag(complexity)
                            }
                        }
                        .pickerStyle(.segmented)
                        Text(numberComplexity.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } header: {
                        Text("Number Complexity")
                    } footer: {
                        Text("Changes apply to new matrices")
                    }

                    Section("Animation Speed") {
                        Picker("Speed", selection: $animationSpeed) {
                            ForEach(AnimationSpeed.allCases, id: \.self) { speed in
                                Text(speed.title).tag(speed)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Section("Addition Style") {
                        Picker("Style", selection: $additionMode) {
                            ForEach(AdditionMode.allCases, id: \.self) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .navigationTitle("Preferences")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            showingPreferences = false
                        }
                    }
                }
            }
        }
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
        sequenceTask?.cancel()
        matrixA = Matrix(rows: rowsA, cols: shared, complexity: numberComplexity)
        matrixB = Matrix(rows: shared, cols: colsB, complexity: numberComplexity)
        result = nil
        selectedResultRow = nil
        selectedResultCol = nil
        animationSelectedRow = nil
        animationSelectedCol = nil
        animationResultValue = nil
        animationResultCellFrame = nil
        showingAnimation = false
        resultStamps = [:]
        isAnimatingSequence = false
        isSequencePaused = false
    }

    private func reset() {
        sequenceTask?.cancel()
        matrixA = Matrix(rows: rowsA, cols: shared, complexity: numberComplexity)
        matrixB = Matrix(rows: shared, cols: colsB, complexity: numberComplexity)
        result = nil
        selectedResultRow = nil
        selectedResultCol = nil
        animationSelectedRow = nil
        animationSelectedCol = nil
        animationResultValue = nil
        animationResultCellFrame = nil
        showingAnimation = false
        resultStamps = [:]
        isAnimatingSequence = false
        isSequencePaused = false
    }

    private func resultStampView(id: ResultCellIdentifier, frame: CGRect, value: Int) -> some View {
        Text("\(value)")
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .frame(width: 50, height: 50)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.green.opacity(0.9)))
            .scaleEffect(0.9)
            .position(x: frame.midX, y: frame.midY)
    }

    private var sortedResultStampIds: [ResultCellIdentifier] {
        resultStamps.keys.sorted { lhs, rhs in
            if lhs.row != rhs.row {
                return lhs.row < rhs.row
            }
            return lhs.col < rhs.col
        }
    }

    private func resultCellFrame(for id: ResultCellIdentifier) -> CGRect? {
        resultCellPositions.first { $0.id.row == id.row && $0.id.col == id.col }?.frame
    }

    private func startSequentialAnimation() {
        guard !isAnimatingSequence else { return }
        guard let result else { return }
        isAnimatingSequence = true
        sequenceTask?.cancel()
        sequenceTask = Task { @MainActor in
            let rows = result.count
            let cols = result.first?.count ?? 0
            for row in 0..<rows {
                for col in 0..<cols {
                    if resultStamps[ResultCellIdentifier(row: row, col: col)] != nil {
                        continue
                    }
                    await waitForSequenceResume()
                    await animateResultCell(row: row, col: col, result: result)
                    if Task.isCancelled { break }
                }
                if Task.isCancelled { break }
            }
            isAnimatingSequence = false
            isSequencePaused = false
            showingAnimation = false
        }
    }

    private func startRandomAnimation() {
        guard !isAnimatingSequence else { return }
        guard let result else { return }
        isAnimatingSequence = true
        sequenceTask?.cancel()
        sequenceTask = Task { @MainActor in
            let rows = result.count
            let cols = result.first?.count ?? 0
            var ids: [ResultCellIdentifier] = []
            ids.reserveCapacity(rows * cols)
            for row in 0..<rows {
                for col in 0..<cols {
                    ids.append(ResultCellIdentifier(row: row, col: col))
                }
            }
            ids.shuffle()
            for id in ids {
                if resultStamps[id] != nil {
                    continue
                }
                await waitForSequenceResume()
                await animateResultCell(row: id.row, col: id.col, result: result)
                if Task.isCancelled { break }
            }
            isAnimatingSequence = false
            isSequencePaused = false
            showingAnimation = false
        }
    }

    private func animateResultCell(row: Int, col: Int, result: [[Int]]) async {
        selectedResultRow = row
        selectedResultCol = col
        await waitForAnimationData(row: row, col: col)
        animationSelectedRow = row
        animationSelectedCol = col
        animationResultValue = result[row][col]
        animationResultCellFrame = resultCellPositions.first {
            $0.id.row == row && $0.id.col == col
        }?.frame
        animationRunId = UUID()
        showingAnimation = true

        let count = matrixA.cols
        let finalSum = result[row][col]
        let duration = MultiplicationAnimationOverlay.totalDuration(count: count, speed: animationSpeed, additionMode: additionMode, finalSum: finalSum)
        let buffer: Double = animationSpeed == .fastest ? 0.02 : (animationSpeed == .fast ? 0.08 : 0.15)
        let total = duration + buffer
        await waitWhilePaused(totalDuration: total)
    }

    private func waitForAnimationData(row: Int, col: Int) async {
        let maxAttempts = 20
        let delayNanos: UInt64 = 30_000_000
        for _ in 0..<maxAttempts {
            if hasAnimationData(row: row, col: col) {
                return
            }
            try? await Task.sleep(nanoseconds: delayNanos)
        }
    }

    private func hasAnimationData(row: Int, col: Int) -> Bool {
        let rowCount = cellPositions.filter { $0.id.matrix == 0 && $0.id.row == row }.count
        let colCount = cellPositions.filter { $0.id.matrix == 1 && $0.id.col == col }.count
        let resultFrameAvailable = resultCellPositions.contains { $0.id.row == row && $0.id.col == col }
        return rowCount == matrixA.cols && colCount == matrixB.rows && resultFrameAvailable
    }

    private func waitForSequenceResume() async {
        while isSequencePaused {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }

    private func waitWhilePaused(totalDuration: Double) async {
        let step: Double = 0.1
        var remaining = totalDuration
        while remaining > 0 {
            if isSequencePaused {
                await waitForSequenceResume()
            } else {
                let slice = min(step, remaining)
                let nanos = UInt64(slice * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanos)
                remaining -= slice
            }
        }
    }
}

#Preview {
    ContentView()
}
