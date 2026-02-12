//
//  ArithmeticAnswerRowView.swift
//  Multrix
//

import SwiftUI

struct ArithmeticAnswerRowView: View {
    let problem: ArithmeticProblem
    let displayMode: ArithmeticDisplayMode
    let showAnswer: Bool
    let onToggleShowAnswer: () -> Void
    let canExplain: Bool
    let onExplain: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text("=")
                .font(.title2)
                .fontWeight(.semibold)

            Text(showAnswer ? problem.answerDisplay(mode: displayMode) : "...")
                .font(.title2)
                .fontWeight(.semibold)
                .monospacedDigit()

            Button(showAnswer ? "Hide" : "Show") {
                onToggleShowAnswer()
            }
            .buttonStyle(.bordered)

            if showAnswer && canExplain {
                Button("Explain") {
                    onExplain()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
