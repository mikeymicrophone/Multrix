//
//  ArithmeticPracticeView.swift
//  Multrix
//

import SwiftUI
import SwiftData

struct ArithmeticPracticeView: View {
    let title: String
    let operations: [ArithmeticOperation]
    let settings: ArithmeticProblemSettings
    let historyGroup: String

    @State private var problem: ArithmeticProblem
    @State private var showAnswer = false
    @State private var displayMode: ArithmeticDisplayMode = .full
    @State private var sortOption: HistorySortOption = .newest
    @State private var showingNumberInput = false
    @State private var editingTarget: OperandEditTarget?
    @Environment(\.modelContext) private var modelContext
    @Query private var historyEntries: [ArithmeticHistoryEntry]

    init(
        title: String,
        operations: [ArithmeticOperation],
        historyGroup: String,
        settings: ArithmeticProblemSettings = ArithmeticProblemSettings()
    ) {
        self.title = title
        self.operations = operations
        self.settings = settings
        self.historyGroup = historyGroup
        _problem = State(initialValue: ArithmeticProblemGenerator.generate(operations: operations, settings: settings))
        _historyEntries = Query(
            filter: #Predicate<ArithmeticHistoryEntry> { entry in
                entry.group == historyGroup
            },
            sort: \.createdAt,
            order: .reverse
        )
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text(title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)

                    ArithmeticModePickerView(displayMode: $displayMode)
                    ArithmeticEquationRowView(
                        problem: problem,
                        displayMode: displayMode,
                        onEditLhs: { startEditing(.lhs) },
                        onToggleOperation: toggleOperation,
                        onEditRhs: { startEditing(.rhs) },
                        onRefresh: refreshProblem
                    )
                    ArithmeticAnswerRowView(
                        problem: problem,
                        displayMode: displayMode,
                        showAnswer: showAnswer,
                        onToggleShowAnswer: toggleShowAnswer
                    )
                    ArithmeticReviewPanelView(
                        historyEntries: sortedHistoryEntries,
                        sortOption: $sortOption
                    )

                    Spacer(minLength: 0)
                }
                .padding()
            }

            numberInputOverlay
        }
        .onAppear { ensureUniqueProblem() }
    }

    @ViewBuilder
    private var numberInputOverlay: some View {
        if showingNumberInput {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    showingNumberInput = false
                    editingTarget = nil
                }

            NumberInputView(
                isPresented: $showingNumberInput,
                showsDecimalToggle: true
            ) { number in
                applyNumberInput(number)
            }
        }
    }

    private func toggleShowAnswer() {
        let nextValue = !showAnswer
        if nextValue {
            recordCurrentProblem()
        }
        showAnswer = nextValue
    }

    private func refreshProblem() {
        recordCurrentProblem()
        problem = generateNextProblem()
        showAnswer = false
    }

    private func recordCurrentProblem() {
        let key = historyKey(for: problem)
        if historyEntries.contains(where: { historyKey(for: $0) == key }) { return }
        let entry = ArithmeticHistoryEntry(
            id: problem.id,
            lhs: problem.lhs,
            rhs: problem.rhs,
            operation: problem.operation,
            displayMode: displayMode,
            answer: problem.answer,
            group: historyGroup
        )
        modelContext.insert(entry)
    }

    private var sortedHistoryEntries: [ArithmeticHistoryEntry] {
        switch sortOption {
        case .newest:
            return historyEntries.sorted { $0.createdAt > $1.createdAt }
        case .oldest:
            return historyEntries.sorted { $0.createdAt < $1.createdAt }
        case .answerAscending:
            return historyEntries.sorted {
                if $0.answer == $1.answer { return $0.createdAt > $1.createdAt }
                return $0.answer < $1.answer
            }
        case .answerDescending:
            return historyEntries.sorted {
                if $0.answer == $1.answer { return $0.createdAt > $1.createdAt }
                return $0.answer > $1.answer
            }
        }
    }

    private func generateNextProblem() -> ArithmeticProblem {
        let maxAttempts = 120
        let existingKeys = historyKeys().union([historyKey(for: problem)])
        for _ in 0..<maxAttempts {
            let candidate = ArithmeticProblemGenerator.generate(operations: operations, settings: settings)
            if !existingKeys.contains(historyKey(for: candidate)) {
                return candidate
            }
        }
        return ArithmeticProblemGenerator.generate(operations: operations, settings: settings)
    }

    private func ensureUniqueProblem() {
        let key = historyKey(for: problem)
        if historyEntries.contains(where: { historyKey(for: $0) == key }) {
            problem = generateNextProblem()
            showAnswer = false
        }
    }

    private func startEditing(_ target: OperandEditTarget) {
        editingTarget = target
        showingNumberInput = true
    }

    private func applyNumberInput(_ number: Double) {
        guard let editingTarget else { return }

        switch editingTarget {
        case .lhs:
            setProblem(lhs: number, rhs: problem.rhs, operation: problem.operation)
        case .rhs:
            setProblem(lhs: problem.lhs, rhs: number, operation: problem.operation)
        }

        self.editingTarget = nil
    }

    private func toggleOperation() {
        guard !operations.isEmpty else { return }
        if operations.count == 1 {
            setProblem(lhs: problem.lhs, rhs: problem.rhs, operation: operations[0])
            return
        }

        let nextOperation: ArithmeticOperation
        if let currentIndex = operations.firstIndex(of: problem.operation) {
            nextOperation = operations[(currentIndex + 1) % operations.count]
        } else {
            nextOperation = operations[0]
        }

        setProblem(lhs: problem.lhs, rhs: problem.rhs, operation: nextOperation)
    }

    private func setProblem(lhs: Double, rhs: Double, operation: ArithmeticOperation) {
        let answer = operation.apply(lhs: lhs, rhs: rhs)
        problem = ArithmeticProblem(lhs: lhs, rhs: rhs, operation: operation, answer: answer)
        showAnswer = false
    }

    private func historyKeys() -> Set<HistoryKey> {
        Set(historyEntries.map { historyKey(for: $0) })
    }

    private func historyKey(for problem: ArithmeticProblem) -> HistoryKey {
        HistoryKey(
            operation: problem.operation,
            lhsScaled: scaledValue(problem.lhs),
            rhsScaled: scaledValue(problem.rhs)
        )
    }

    private func historyKey(for entry: ArithmeticHistoryEntry) -> HistoryKey {
        HistoryKey(
            operation: entry.operation,
            lhsScaled: scaledValue(entry.lhs),
            rhsScaled: scaledValue(entry.rhs)
        )
    }

    private func scaledValue(_ value: Double) -> Int {
        let step = max(settings.decimalStep, 0.01)
        let factor = Int((1.0 / step).rounded())
        return Int((value * Double(factor)).rounded())
    }
}

#Preview {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: ArithmeticHistoryEntry.self, configurations: configuration)
    ArithmeticPracticeView(
        title: "Addition & Subtraction",
        operations: [.addition, .subtraction],
        historyGroup: "addSub"
    )
    .modelContainer(container)
}

private struct HistoryKey: Hashable {
    let operation: ArithmeticOperation
    let lhsScaled: Int
    let rhsScaled: Int
}

enum HistorySortOption: String, CaseIterable, Identifiable {
    case newest
    case oldest
    case answerAscending
    case answerDescending

    var id: String { rawValue }

    var title: String {
        switch self {
        case .newest: return "Newest"
        case .oldest: return "Oldest"
        case .answerAscending: return "Answer (Low)"
        case .answerDescending: return "Answer (High)"
        }
    }
}

private enum OperandEditTarget {
    case lhs
    case rhs
}
