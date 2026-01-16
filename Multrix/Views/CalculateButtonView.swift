//
//  CalculateButtonView.swift
//  Multrix
//

import SwiftUI

struct CalculateButtonView: View {
    let canCalculate: Bool
    let showIncompleteMessage: Bool
    let onCalculate: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Button(action: onCalculate) {
                Text("Multiply")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(canCalculate ? Color.blue : Color.gray)
                    .cornerRadius(12)
            }
            .accessibilityIdentifier("calculate.multiply")
            .disabled(!canCalculate)

            if showIncompleteMessage {
                Text("Fill in the missing numbers to calculate")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Previews

#Preview("Can Calculate") {
    CalculateButtonView(
        canCalculate: true,
        showIncompleteMessage: false,
        onCalculate: {}
    )
}

#Preview("Cannot Calculate - Incomplete") {
    CalculateButtonView(
        canCalculate: false,
        showIncompleteMessage: true,
        onCalculate: {}
    )
}

#Preview("Cannot Calculate - Already Calculated") {
    CalculateButtonView(
        canCalculate: false,
        showIncompleteMessage: false,
        onCalculate: {}
    )
}
