//
//  TablePracticeView.swift
//  Multrix
//

import SwiftUI

struct TablePracticeView: View {
    let title: String
    let operation: OperationType
    @Binding var stats: [FactKey: FactStats]
    @Binding var showAnswers: Bool
    @Binding var guessMode: GuessMode

    private let maxNumber = 12
    @State private var activeFact: FactKey? = nil

    private var numbers: [Int] {
        Array(0...maxNumber)
    }

    private var totalFacts: Int {
        (maxNumber + 1) * (maxNumber + 1)
    }

    private var summary: PracticeSummary {
        let totals = stats.values.reduce(into: (attempts: 0, correct: 0, mastered: 0)) { partial, stat in
            partial.attempts += stat.attempts
            partial.correct += stat.correct
            if stat.isMastered { partial.mastered += 1 }
        }
        return PracticeSummary(
            attempts: totals.attempts,
            correct: totals.correct,
            mastered: totals.mastered,
            total: totalFacts
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Toggle("Show answers", isOn: $showAnswers)

                    Picker("Guess type", selection: $guessMode) {
                        ForEach(GuessMode.allCases, id: \.self) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Attempts: \(summary.attempts)")
                        Text("Correct: \(summary.correct)")
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Accuracy: \(summary.accuracyFormatted)")
                        Text("Mastered: \(summary.mastered)/\(summary.total)")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                ScrollView([.vertical, .horizontal]) {
                    LazyVGrid(columns: gridColumns, spacing: 8) {
                        ForEach(0...numbers.count, id: \.self) { rowIndex in
                            ForEach(0...numbers.count, id: \.self) { colIndex in
                                tableCell(rowIndex: rowIndex, colIndex: colIndex)
                            }
                        }
                    }
                    .padding(.bottom, 16)
                }
            }
            .padding()
            .navigationTitle(title)
        }
        .sheet(item: $activeFact) { fact in
            AnswerSheetView(
                operation: operation,
                fact: fact,
                maxNumber: maxNumber,
                guessMode: guessMode
            ) { isCorrect in
                recordGuess(for: fact, isCorrect: isCorrect)
            }
        }
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(minimum: 36), spacing: 8), count: numbers.count + 1)
    }

    @ViewBuilder
    private func tableCell(rowIndex: Int, colIndex: Int) -> some View {
        if rowIndex == 0 && colIndex == 0 {
            Text(operation.symbol)
                .font(.headline)
                .frame(minWidth: 36, minHeight: 36)
        } else if rowIndex == 0 {
            Text("\(numbers[colIndex - 1])")
                .font(.headline)
                .frame(minWidth: 36, minHeight: 36)
        } else if colIndex == 0 {
            Text("\(numbers[rowIndex - 1])")
                .font(.headline)
                .frame(minWidth: 36, minHeight: 36)
        } else {
            let rowValue = numbers[rowIndex - 1]
            let colValue = numbers[colIndex - 1]
            let key = FactKey(row: rowValue, col: colValue)
            let answer = operation.result(lhs: rowValue, rhs: colValue)
            let stat = stats[key]

            Button {
                activeFact = key
            } label: {
                Text(showAnswers ? "\(answer)" : "")
                    .font(.subheadline)
                    .frame(minWidth: 36, minHeight: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(cellBackground(for: stat))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(cellBorder(for: stat), lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    private func cellBackground(for stat: FactStats?) -> Color {
        guard let stat else {
            return Color.gray.opacity(0.15)
        }
        if stat.isMastered {
            return Color.green.opacity(0.25)
        }
        if stat.attempts > 0 {
            return Color.yellow.opacity(0.25)
        }
        return Color.gray.opacity(0.15)
    }

    private func cellBorder(for stat: FactStats?) -> Color {
        guard let stat else { return Color.clear }
        guard let lastCorrect = stat.lastCorrect else { return Color.clear }
        return lastCorrect ? Color.green.opacity(0.6) : Color.red.opacity(0.6)
    }

    private func recordGuess(for key: FactKey, isCorrect: Bool) {
        var current = stats[key] ?? FactStats()
        current.record(isCorrect: isCorrect)
        stats[key] = current
    }
}

private struct PracticeSummary {
    let attempts: Int
    let correct: Int
    let mastered: Int
    let total: Int

    var accuracyFormatted: String {
        guard attempts > 0 else { return "0%" }
        let accuracy = Double(correct) / Double(attempts)
        return "\(Int((accuracy * 100).rounded()))%"
    }
}

#Preview {
    TablePracticeView(
        title: "Addition Table",
        operation: .addition,
        stats: .constant([:]),
        showAnswers: .constant(true),
        guessMode: .constant(.multipleChoice)
    )
}
