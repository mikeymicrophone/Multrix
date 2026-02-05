//
//  ContentView.swift
//  Multrix
//

import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: - Matrix State

    @State private var rowsA: Int = 4
    @State private var shared: Int = 4
    @State private var colsB: Int = 4
    @State private var matrixA: Matrix
    @State private var matrixB: Matrix
    @State private var result: [[Int]]? = nil

    // MARK: - Selection State

    @State private var selectedResultRow: Int? = nil
    @State private var selectedResultCol: Int? = nil

    // MARK: - Number Input State

    @State private var showingNumberInput = false
    @State private var editingMatrix: Int = 0
    @State private var editingRow: Int = 0
    @State private var editingCol: Int = 0

    // MARK: - Animation State

    @State private var showingAnimation = false
    @State private var animationRunId = UUID()
    @State private var animationSelectedRow: Int? = nil
    @State private var animationSelectedCol: Int? = nil
    @State private var animationResultValue: Int? = nil
    @State private var animationResultCellFrame: CGRect? = nil
    @State private var resultStamps: [ResultCellIdentifier: Int] = [:]
    @State private var isAnimatingSequence = false
    @State private var isSequencePaused = false
    @State private var sequenceTask: Task<Void, Never>? = nil
    @State private var cellPositions: [CellPositionData] = []
    @State private var resultCellPositions: [ResultCellPositionData] = []
    @State private var animationTargetArea: CGRect = .zero

    // MARK: - Change Game State

    @State private var changeGameActive = false
    @State private var changeGameBaseResult: [[Int]]? = nil
    @State private var changeGameChangedCells: Set<ResultCellIdentifier> = []
    @State private var changeGameTarget: CellIdentifier? = nil
    @State private var changeGameOriginalValue: Int? = nil
    @State private var changeGameNewValue: Int? = nil
    @State private var changeGameMessage: String? = nil
    @State private var showOriginalResult = false

    // MARK: - Preferences State

    @State private var animationSpeed: AnimationSpeed = .normal
    @State private var additionMode: AdditionMode = .collapse
    @State private var numberComplexity: NumberComplexity = .moderate
    @State private var showingPreferences = false
    @State private var pendingRowsA: Int = 4
    @State private var pendingShared: Int = 4
    @State private var pendingColsB: Int = 4
    @State private var pendingComplexity: NumberComplexity = .moderate

    // MARK: - Computed Properties

    private var canCalculate: Bool {
        matrixA.isComplete && matrixB.isComplete && result == nil
    }

    private var isAnimating: Bool {
        isAnimatingSequence || showingAnimation
    }

    private var sortedResultStampIds: [ResultCellIdentifier] {
        resultStamps.keys.sorted { lhs, rhs in
            if lhs.row != rhs.row { return lhs.row < rhs.row }
            return lhs.col < rhs.col
        }
    }

    private var effectiveSelectedRow: Int? {
        selectedResultRow
    }

    private var effectiveSelectedCol: Int? {
        selectedResultCol
    }

    private var displayResult: [[Int]]? {
        if changeGameActive, showOriginalResult, let baseResult = changeGameBaseResult {
            return baseResult
        }
        return result
    }

    // MARK: - Init

    init() {
        _matrixA = State(initialValue: Matrix(rows: 4, cols: 4))
        _matrixB = State(initialValue: Matrix(rows: 4, cols: 4))
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { outerGeo in
            let contentWidth = min(outerGeo.size.width - 32, 560)

            ZStack {
                mainContent(contentWidth: contentWidth)
                animationOverlay
                resultStampsOverlay
                numberInputOverlay
            }
        }
        .animation(.easeInOut, value: result != nil)
        .animation(.easeInOut, value: showingNumberInput)
        .animation(.easeInOut, value: selectedResultRow)
        .animation(.easeInOut, value: selectedResultCol)
        .animation(.easeInOut, value: showingAnimation)
        .animation(.easeInOut, value: isAnimatingSequence)
        .sheet(isPresented: $showingPreferences, onDismiss: applyPreferencesIfChanged) {
            PreferencesSheetView(
                rowsA: $pendingRowsA,
                shared: $pendingShared,
                colsB: $pendingColsB,
                complexity: $pendingComplexity,
                animationSpeed: $animationSpeed,
                additionMode: $additionMode,
                onDone: { showingPreferences = false }
            )
        }
    }

    // MARK: - Main Content

    private func mainContent(contentWidth: CGFloat) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                HeaderToolbarView(
                    isAnimating: isAnimating,
                    isPaused: isSequencePaused,
                    onPauseTapped: { isSequencePaused.toggle() },
                    onSettingsTapped: openPreferences
                )

                Text("Matrix Multiplication")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                InputMatricesSectionView(
                    matrixA: $matrixA,
                    matrixB: $matrixB,
                    selectedResultRow: selectedResultRow,
                    selectedResultCol: selectedResultCol,
                    sharedDimension: shared,
                    onCellTapped: handleCellTapped,
                    onAnimationAreaChanged: { animationTargetArea = $0 }
                )

                CalculateButtonView(
                    canCalculate: canCalculate,
                    showIncompleteMessage: !matrixA.isComplete || !matrixB.isComplete,
                    onCalculate: calculateResult
                )

                if let result = result {
                    ResultSectionView(
                        result: displayResult ?? result,
                        matrixA: matrixA,
                        matrixB: matrixB,
                        selectedRow: effectiveSelectedRow,
                        selectedCol: effectiveSelectedCol,
                        isAnimatingSequence: isAnimatingSequence,
                        isChangeGameActive: changeGameActive,
                        changedResultCells: changeGameActive ? changeGameChangedCells : [],
                        changeGameMessage: changeGameMessage,
                        isChangeGameButtonDisabled: isAnimating,
                        showOriginalResult: $showOriginalResult,
                        contentWidth: contentWidth,
                        onCellSelected: { row, col in
                            if changeGameActive, let row, let col {
                                let id = ResultCellIdentifier(row: row, col: col)
                                if changeGameChangedCells.contains(id) { return }
                            }
                            handleResultCellSelected(row: row, col: col)
                        },
                        onAnimateTapped: animateSelectedCell,
                        onAnimateAllTapped: startSequentialAnimation,
                        onAnimateRandomTapped: startRandomAnimation,
                        onChangeGameTapped: startChangeGame
                    )
                }

                ResetButtonView(onReset: reset)
            }
            .padding()
        }
        .scrollDisabled(isAnimating)
        .coordinateSpace(name: MatrixCoordinateSpace.name)
        .onPreferenceChange(CellPositionPreferenceKey.self) { cellPositions = $0 }
        .onPreferenceChange(ResultCellPositionPreferenceKey.self) { resultCellPositions = $0 }
    }

    // MARK: - Overlays

    @ViewBuilder
    private var animationOverlay: some View {
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
                onResultPlaced: { _, value in
                    let id = ResultCellIdentifier(row: selectedRow, col: selectedCol)
                    resultStamps[id] = value
                },
                onAnimationFinished: {
                    if !isAnimatingSequence {
                        showingAnimation = false
                    }
                }
            )
            .id(animationRunId)
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var resultStampsOverlay: some View {
        Group {
            if !changeGameActive {
                ForEach(sortedResultStampIds, id: \.self) { id in
                    if let frame = resultCellFrame(for: id), let value = resultStamps[id] {
                        ResultStampView(value: value, frame: frame)
                            .allowsHitTesting(false)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var numberInputOverlay: some View {
        if showingNumberInput {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { showingNumberInput = false }

            NumberInputView(isPresented: $showingNumberInput) { number in
                if editingMatrix == 0 {
                    matrixA.values[editingRow][editingCol] = number
                } else {
                    matrixB.values[editingRow][editingCol] = number
                }
                if changeGameActive {
                    updateResultForChangeGame()
                } else {
                    result = nil
                    selectedResultRow = nil
                    selectedResultCol = nil
                    clearChangeGameState()
                }
            }
        }
    }
}

// MARK: - Actions

extension ContentView {
    private func handleCellTapped(matrix: Int, row: Int, col: Int) {
        editingMatrix = matrix
        editingRow = row
        editingCol = col
        showingNumberInput = true
    }

    private func handleResultCellSelected(row: Int?, col: Int?) {
        selectedResultRow = row
        selectedResultCol = col
    }

    private func openPreferences() {
        pendingRowsA = rowsA
        pendingShared = shared
        pendingColsB = colsB
        pendingComplexity = numberComplexity
        showingPreferences = true
    }

    private func applyPreferencesIfChanged() {
        let dimensionsChanged = pendingRowsA != rowsA || pendingShared != shared || pendingColsB != colsB
        let complexityChanged = pendingComplexity != numberComplexity

        if dimensionsChanged || complexityChanged {
            rowsA = pendingRowsA
            shared = pendingShared
            colsB = pendingColsB
            numberComplexity = pendingComplexity
            regenerateMatrices()
        }
    }

    private func calculateResult() {
        clearChangeGameState()
        let resultRows = matrixA.rows
        let resultCols = matrixB.cols
        let sharedDim = matrixA.cols

        result = computeResultMatrix(rows: resultRows, cols: resultCols, sharedDim: sharedDim, matrixA: matrixA, matrixB: matrixB)
        selectedResultRow = 0
        selectedResultCol = 0
    }

    private func regenerateMatrices() {
        sequenceTask?.cancel()
        matrixA = Matrix(rows: rowsA, cols: shared, complexity: numberComplexity)
        matrixB = Matrix(rows: shared, cols: colsB, complexity: numberComplexity)
        clearAnimationState()
    }

    private func reset() {
        sequenceTask?.cancel()
        matrixA = Matrix(rows: rowsA, cols: shared, complexity: numberComplexity)
        matrixB = Matrix(rows: shared, cols: colsB, complexity: numberComplexity)
        clearAnimationState()
    }

    private func clearAnimationState() {
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
        clearChangeGameState()
    }

    private func animateSelectedCell() {
        guard let row = selectedResultRow,
              let col = selectedResultCol,
              let result = result else { return }

        animationSelectedRow = row
        animationSelectedCol = col
        animationResultValue = result[row][col]
        animationResultCellFrame = resultCellPositions.first {
            $0.id.row == row && $0.id.col == col
        }?.frame
        animationRunId = UUID()
        showingAnimation = true
    }
}

// MARK: - Animation Sequences

extension ContentView {
    private func startSequentialAnimation() {
        guard !isAnimatingSequence, let result else { return }
        isAnimatingSequence = true
        sequenceTask?.cancel()
        sequenceTask = Task { @MainActor in
            let rows = result.count
            let cols = result.first?.count ?? 0
            for row in 0..<rows {
                for col in 0..<cols {
                    if resultStamps[ResultCellIdentifier(row: row, col: col)] != nil { continue }
                    await waitForSequenceResume()
                    await animateResultCell(row: row, col: col, result: result)
                    if Task.isCancelled { break }
                }
                if Task.isCancelled { break }
            }
            finishAnimationSequence()
        }
    }

    private func startRandomAnimation() {
        guard !isAnimatingSequence, let result else { return }
        isAnimatingSequence = true
        sequenceTask?.cancel()
        sequenceTask = Task { @MainActor in
            let rows = result.count
            let cols = result.first?.count ?? 0
            var ids = (0..<rows).flatMap { row in
                (0..<cols).map { ResultCellIdentifier(row: row, col: $0) }
            }
            ids.shuffle()

            for id in ids {
                if resultStamps[id] != nil { continue }
                await waitForSequenceResume()
                await animateResultCell(row: id.row, col: id.col, result: result)
                if Task.isCancelled { break }
            }
            finishAnimationSequence()
        }
    }

    private func finishAnimationSequence() {
        isAnimatingSequence = false
        isSequencePaused = false
        showingAnimation = false
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
        let duration = MultiplicationAnimationOverlay.totalDuration(
            count: count,
            speed: animationSpeed,
            additionMode: additionMode,
            finalSum: finalSum
        )
        let buffer: Double = animationSpeed == .fastest ? 0.02 : (animationSpeed == .fast ? 0.08 : 0.15)
        await waitWhilePaused(totalDuration: duration + buffer)
    }
}

// MARK: - Helpers

extension ContentView {
    private func resultCellFrame(for id: ResultCellIdentifier) -> CGRect? {
        resultCellPositions.first { $0.id.row == id.row && $0.id.col == id.col }?.frame
    }

    private func computeResultMatrix(rows: Int, cols: Int, sharedDim: Int, matrixA: Matrix, matrixB: Matrix) -> [[Int]] {
        var resultMatrix: [[Int]] = Array(
            repeating: Array(repeating: 0, count: cols),
            count: rows
        )

        for i in 0..<rows {
            for j in 0..<cols {
                var sum = 0
                for k in 0..<sharedDim {
                    let a = matrixA.values[i][k] ?? 0
                    let b = matrixB.values[k][j] ?? 0
                    sum += a * b
                }
                resultMatrix[i][j] = sum
            }
        }

        return resultMatrix
    }

    private func waitForAnimationData(row: Int, col: Int) async {
        let maxAttempts = 20
        let delayNanos: UInt64 = 30_000_000
        for _ in 0..<maxAttempts {
            if hasAnimationData(row: row, col: col) { return }
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
                try? await Task.sleep(nanoseconds: UInt64(slice * 1_000_000_000))
                remaining -= slice
            }
        }
    }
}

// MARK: - Change Game

extension ContentView {
    private func startChangeGame() {
        guard let baseResult = result else { return }
        guard !isAnimating else { return }

        changeGameMessage = "Fix the input value that changed."
        changeGameChangedCells = []
        changeGameBaseResult = baseResult
        changeGameTarget = nil
        changeGameOriginalValue = nil
        changeGameNewValue = nil
        showOriginalResult = false
        resultStamps = [:]
        showingAnimation = false
        isAnimatingSequence = false
        sequenceTask?.cancel()

        let maxAttempts = 40
        var attempt = 0

        while attempt < maxAttempts {
            attempt += 1
            let targetMatrix = Bool.random() ? 0 : 1
            let targetRows = targetMatrix == 0 ? matrixA.rows : matrixB.rows
            let targetCols = targetMatrix == 0 ? matrixA.cols : matrixB.cols

            let targetRow = Int.random(in: 0..<targetRows)
            let targetCol = Int.random(in: 0..<targetCols)
            let originalValue = targetMatrix == 0
                ? matrixA.values[targetRow][targetCol]
                : matrixB.values[targetRow][targetCol]

            guard let originalValue else { continue }

            var newValue = originalValue
            var valueAttempts = 0
            while newValue == originalValue && valueAttempts < 20 {
                newValue = numberComplexity.randomValue()
                valueAttempts += 1
            }
            if newValue == originalValue {
                newValue = originalValue + 1
            }

            var modifiedA = matrixA
            var modifiedB = matrixB
            if targetMatrix == 0 {
                modifiedA.values[targetRow][targetCol] = newValue
            } else {
                modifiedB.values[targetRow][targetCol] = newValue
            }

            let modifiedResult = computeResultMatrix(
                rows: modifiedA.rows,
                cols: modifiedB.cols,
                sharedDim: modifiedA.cols,
                matrixA: modifiedA,
                matrixB: modifiedB
            )

            let changedCells = changedResultCells(base: baseResult, modified: modifiedResult)
            if changedCells.isEmpty { continue }

            changeGameActive = true
            if targetMatrix == 0 {
                matrixA.values[targetRow][targetCol] = newValue
            } else {
                matrixB.values[targetRow][targetCol] = newValue
            }
            result = modifiedResult
            changeGameChangedCells = changedCells
            changeGameTarget = CellIdentifier(matrix: targetMatrix, row: targetRow, col: targetCol)
            changeGameOriginalValue = originalValue
            changeGameNewValue = newValue
            if let selectedResultRow, let selectedResultCol {
                let selectedId = ResultCellIdentifier(row: selectedResultRow, col: selectedResultCol)
                if changedCells.contains(selectedId) {
                    self.selectedResultRow = nil
                    self.selectedResultCol = nil
                }
            }
            return
        }

        changeGameActive = false
        changeGameMessage = "Couldn't generate a change. Try again."
    }

    private func changedResultCells(base: [[Int]], modified: [[Int]]) -> Set<ResultCellIdentifier> {
        var changed: Set<ResultCellIdentifier> = []
        for row in 0..<min(base.count, modified.count) {
            for col in 0..<min(base[row].count, modified[row].count) {
                if base[row][col] != modified[row][col] {
                    changed.insert(ResultCellIdentifier(row: row, col: col))
                }
            }
        }
        return changed
    }

    private func updateResultForChangeGame() {
        guard changeGameActive else { return }
        let updatedResult = computeResultMatrix(
            rows: matrixA.rows,
            cols: matrixB.cols,
            sharedDim: matrixA.cols,
            matrixA: matrixA,
            matrixB: matrixB
        )
        result = updatedResult

        if let baseResult = changeGameBaseResult {
            changeGameChangedCells = changedResultCells(base: baseResult, modified: updatedResult)
        } else {
            changeGameChangedCells = []
        }

        if let selectedResultRow, let selectedResultCol {
            let selectedId = ResultCellIdentifier(row: selectedResultRow, col: selectedResultCol)
            if changeGameChangedCells.contains(selectedId) {
                self.selectedResultRow = nil
                self.selectedResultCol = nil
            }
        }

        guard changeGameChangedCells.isEmpty,
              let target = changeGameTarget,
              let originalValue = changeGameOriginalValue else { return }

        let currentValue = target.matrix == 0
            ? matrixA.values[target.row][target.col]
            : matrixB.values[target.row][target.col]
        if currentValue == originalValue {
            let matrixName = target.matrix == 0 ? "Matrix A" : "Matrix B"
            changeGameMessage = "Nice! \(matrixName) cell \(target.row + 1),\(target.col + 1) is fixed."
            clearChangeGameState(preserveMessage: true)
        }
    }

    private func clearChangeGameState(preserveMessage: Bool = false) {
        changeGameActive = false
        changeGameBaseResult = nil
        changeGameChangedCells = []
        changeGameTarget = nil
        changeGameOriginalValue = nil
        changeGameNewValue = nil
        showOriginalResult = false
        if !preserveMessage {
            changeGameMessage = nil
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
