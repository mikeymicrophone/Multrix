//
//  AnswerSheetView.swift
//  Multrix
//

import SwiftUI

struct AnswerSheetView: View {
    let operation: OperationType
    let fact: FactKey
    let maxNumber: Int
    let guessMode: GuessMode
    let onSubmit: (Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var freeEntry = ""
    @State private var options: [Int] = []
    @State private var isSubmitted = false
    @State private var isCorrect: Bool? = nil

    private var correctAnswer: Int {
        operation.result(lhs: fact.row, rhs: fact.col)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("\(fact.row) \(operation.symbol) \(fact.col) = ?")
                    .font(.title2)
                    .fontWeight(.semibold)

                if isSubmitted {
                    feedbackView
                } else {
                    answerInputView
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Check")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if guessMode == .multipleChoice {
                    options = buildOptions()
                }
            }
        }
    }

    @ViewBuilder
    private var answerInputView: some View {
        switch guessMode {
        case .multipleChoice:
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(options, id: \.self) { option in
                    Button {
                        submitAnswer(option)
                    } label: {
                        Text("\(option)")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        case .freeEntry:
            VStack(spacing: 12) {
                TextField("Enter your answer", text: $freeEntry)
                    .textFieldStyle(.roundedBorder)
#if os(iOS)
                    .keyboardType(.numberPad)
#endif

                Button("Check") {
                    guard let value = Int(freeEntry.trimmingCharacters(in: .whitespaces)) else { return }
                    submitAnswer(value)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    @ViewBuilder
    private var feedbackView: some View {
        let correctText = "Correct!"
        let incorrectText = "Not quite. The answer is \(correctAnswer)."

        Text(isCorrect == true ? correctText : incorrectText)
            .font(.headline)
            .foregroundStyle(isCorrect == true ? .green : .red)

        Button("Back to table") {
            dismiss()
        }
        .buttonStyle(.bordered)
    }

    private func submitAnswer(_ value: Int) {
        guard !isSubmitted else { return }
        let correct = value == correctAnswer
        isSubmitted = true
        isCorrect = correct
        onSubmit(correct)
    }

    private func buildOptions() -> [Int] {
        let maxValue = operation == .addition ? maxNumber * 2 : maxNumber * maxNumber
        var optionSet: Set<Int> = [correctAnswer]

        while optionSet.count < 4 {
            optionSet.insert(Int.random(in: 0...maxValue))
        }

        return Array(optionSet).shuffled()
    }
}

#Preview {
    AnswerSheetView(
        operation: .multiplication,
        fact: FactKey(row: 3, col: 4),
        maxNumber: 12,
        guessMode: .multipleChoice
    ) { _ in }
}
