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
        ScrollView {
            VStack(spacing: 24) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                modePicker
                problemRow
                answerRow
                reviewPanel

                Spacer(minLength: 0)
            }
            .padding()
        }
        .onAppear { ensureUniqueProblem() }
    }

    private var problemRow: some View {
        HStack(spacing: 12) {
            Text(problem.lhsDisplay(mode: displayMode))
                .font(.title)
                .fontWeight(.semibold)

            Text(problem.operation.symbol)
                .font(.title)
                .fontWeight(.semibold)

            Text(problem.rhsDisplay(mode: displayMode))
                .font(.title)
                .fontWeight(.semibold)

            Button(action: refreshProblem) {
                Image(systemName: "arrow.clockwise")
                    .font(.title3)
                    .padding(8)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(Circle())
            }
            .accessibilityLabel("New problem")
        }
    }

    private var answerRow: some View {
        HStack(spacing: 12) {
            Text("=")
                .font(.title2)
                .fontWeight(.semibold)

            Text(showAnswer ? problem.answerDisplay(mode: displayMode) : "...")
                .font(.title2)
                .fontWeight(.semibold)
                .monospacedDigit()

            Button(showAnswer ? "Hide" : "Show") {
                let nextValue = !showAnswer
                if nextValue {
                    recordCurrentProblem()
                }
                showAnswer = nextValue
            }
            .buttonStyle(.bordered)
        }
    }

    private var reviewPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Text("Review")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Picker("Sort", selection: $sortOption) {
                    ForEach(HistorySortOption.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.menu)
            }

            if historyEntries.isEmpty {
                Text("No completed problems yet.")
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(sortedHistoryEntries.prefix(20)) { item in
                        HStack {
                            Text("\(item.lhsDisplay) \(item.operation.symbol) \(item.rhsDisplay)")
                                .font(.subheadline)

                            Spacer()

                            Text("= \(item.answerDisplay)")
                                .font(.subheadline)
                                .monospacedDigit()
                        }
                        .padding(10)
                        .background(Color.gray.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
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

    private var modePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mode")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker("Mode", selection: $displayMode) {
                ForEach(ArithmeticDisplayMode.allCases, id: \.self) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: ArithmeticHistoryEntry.self, configurations: configuration)
    return ArithmeticPracticeView(
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

private enum HistorySortOption: String, CaseIterable, Identifiable {
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
