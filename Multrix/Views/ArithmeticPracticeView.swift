//
//  ArithmeticPracticeView.swift
//  Multrix
//

import SwiftUI

struct ArithmeticPracticeView: View {
    let title: String
    let operations: [ArithmeticOperation]
    let settings: ArithmeticProblemSettings

    @State private var problem: ArithmeticProblem
    @State private var showAnswer = false

    init(
        title: String,
        operations: [ArithmeticOperation],
        settings: ArithmeticProblemSettings = ArithmeticProblemSettings()
    ) {
        self.title = title
        self.operations = operations
        self.settings = settings
        _problem = State(initialValue: ArithmeticProblemGenerator.generate(operations: operations, settings: settings))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                problemRow
                answerRow

                Spacer(minLength: 0)
            }
            .padding()
        }
    }

    private var problemRow: some View {
        HStack(spacing: 12) {
            Text(problem.lhsDisplay)
                .font(.title)
                .fontWeight(.semibold)

            Text(problem.operation.symbol)
                .font(.title)
                .fontWeight(.semibold)

            Text(problem.rhsDisplay)
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

            Text(showAnswer ? problem.answerDisplay : "...")
                .font(.title2)
                .fontWeight(.semibold)
                .monospacedDigit()

            Button(showAnswer ? "Hide" : "Show") {
                showAnswer.toggle()
            }
            .buttonStyle(.bordered)
        }
    }

    private func refreshProblem() {
        problem = ArithmeticProblemGenerator.generate(operations: operations, settings: settings)
        showAnswer = false
    }
}

#Preview {
    ArithmeticPracticeView(
        title: "Addition & Subtraction",
        operations: [.addition, .subtraction]
    )
}
