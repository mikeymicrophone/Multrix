//
//  ArithmeticExplanationSheetView.swift
//  Multrix
//

import SwiftUI

enum ArithmeticExplanationSupport {
    static func canExplain(_ problem: ArithmeticProblem) -> Bool {
        guard problem.operation == .addition || problem.operation == .subtraction else { return false }
        guard isWholeNumber(problem.lhs), isWholeNumber(problem.rhs) else { return false }
        if problem.operation == .subtraction && problem.lhs < problem.rhs {
            return false
        }
        return true
    }

    private static func isWholeNumber(_ value: Double) -> Bool {
        abs(value.rounded() - value) < 0.000001
    }
}

struct ArithmeticExplanationSheetView: View {
    let problem: ArithmeticProblem

    @Environment(\.dismiss) private var dismiss

    private var work: ArithmeticVerticalWork? {
        ArithmeticVerticalWork(problem: problem)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("\(problem.lhsDisplay(mode: .full)) \(problem.operation.symbol) \(problem.rhsDisplay(mode: .full)) = \(problem.answerDisplay(mode: .full))")
                        .font(.headline)

                    if let work {
                        ArithmeticVerticalNotationView(work: work)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Steps")
                                .font(.headline)
                            ForEach(Array(work.steps.enumerated()), id: \.offset) { index, step in
                                Text("\(index + 1). \(step)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Traditional notation is available for whole-number addition and subtraction.")
                                .font(.subheadline)
                            Text("This problem cannot be shown with carry/borrow notation yet.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Explain")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct ArithmeticVerticalNotationView: View {
    let work: ArithmeticVerticalWork

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if work.operation == .addition && work.hasCarryDigits {
                Text("Carry")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                DigitRowView(
                    prefix: nil,
                    prefixColor: .secondary,
                    digits: work.carryDigits,
                    font: .system(size: 18, weight: .semibold, design: .rounded),
                    digitColor: .secondary
                )
            }

            if work.operation == .subtraction && work.hasBorrowAdjustments {
                Text("Borrow")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                BorrowAdjustmentRowView(adjustments: work.borrowAdjustments)
            }

            DigitRowView(
                prefix: nil,
                prefixColor: .primary,
                digits: work.lhsDigits,
                font: .system(size: 30, weight: .bold, design: .rounded),
                digitColor: .primary
            )

            DigitRowView(
                prefix: work.operation.symbol,
                prefixColor: work.operation.operatorColor,
                digits: work.rhsDigits,
                font: .system(size: 30, weight: .bold, design: .rounded),
                digitColor: .primary
            )

            Rectangle()
                .fill(Color.secondary.opacity(0.45))
                .frame(height: 1)
                .padding(.leading, 24)

            DigitRowView(
                prefix: nil,
                prefixColor: .primary,
                digits: work.resultDigits,
                font: .system(size: 32, weight: .bold, design: .rounded),
                digitColor: .primary
            )
        }
        .padding(12)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct BorrowAdjustmentRowView: View {
    let adjustments: [BorrowAdjustment?]

    var body: some View {
        HStack(spacing: 6) {
            Text(" ")
                .frame(width: 18, alignment: .trailing)

            ForEach(Array(adjustments.enumerated()), id: \.offset) { _, adjustment in
                if let adjustment {
                    HStack(spacing: 2) {
                        Text("\(adjustment.oldDigit)")
                            .strikethrough(true, color: .secondary)
                        Text("\(adjustment.newDigit)")
                    }
                    .frame(width: 22, alignment: .center)
                    .foregroundStyle(.secondary)
                } else {
                    Text(" ")
                        .frame(width: 22, alignment: .center)
                }
            }
        }
        .font(.system(size: 14, weight: .semibold, design: .rounded))
        .monospacedDigit()
    }
}

private struct DigitRowView: View {
    let prefix: String?
    let prefixColor: Color
    let digits: [Int?]
    let font: Font
    let digitColor: Color

    var body: some View {
        HStack(spacing: 6) {
            Text(prefix ?? " ")
                .frame(width: 18, alignment: .trailing)
                .foregroundStyle(prefixColor)

            ForEach(Array(digits.enumerated()), id: \.offset) { _, digit in
                Text(digit.map(String.init) ?? " ")
                    .frame(width: 22, alignment: .center)
                    .foregroundStyle(digitColor)
            }
        }
        .font(font)
        .monospacedDigit()
    }
}

private struct ArithmeticVerticalWork {
    let operation: ArithmeticOperation
    let lhsDigits: [Int?]
    let rhsDigits: [Int?]
    let resultDigits: [Int?]
    let carryDigits: [Int?]
    let borrowAdjustments: [BorrowAdjustment?]
    let steps: [String]

    var hasCarryDigits: Bool {
        carryDigits.contains { $0 != nil }
    }

    var hasBorrowAdjustments: Bool {
        borrowAdjustments.contains { $0 != nil }
    }

    init?(problem: ArithmeticProblem) {
        guard problem.operation == .addition || problem.operation == .subtraction else { return nil }
        guard let lhs = Self.wholeNumber(problem.lhs), let rhs = Self.wholeNumber(problem.rhs) else { return nil }

        switch problem.operation {
        case .addition:
            let built = Self.buildAddition(lhs: lhs, rhs: rhs)
            self.operation = .addition
            self.lhsDigits = built.lhsDigits
            self.rhsDigits = built.rhsDigits
            self.resultDigits = built.resultDigits
            self.carryDigits = built.carryDigits
            self.borrowAdjustments = []
            self.steps = built.steps
        case .subtraction:
            guard lhs >= rhs else { return nil }
            let built = Self.buildSubtraction(lhs: lhs, rhs: rhs)
            self.operation = .subtraction
            self.lhsDigits = built.lhsDigits
            self.rhsDigits = built.rhsDigits
            self.resultDigits = built.resultDigits
            self.carryDigits = []
            self.borrowAdjustments = built.borrowAdjustments
            self.steps = built.steps
        case .multiplication, .division:
            return nil
        }
    }

    private static func buildAddition(lhs: Int, rhs: Int) -> (lhsDigits: [Int?], rhsDigits: [Int?], resultDigits: [Int?], carryDigits: [Int?], steps: [String]) {
        let lhsReversed = Array(digits(of: lhs).reversed())
        let rhsReversed = Array(digits(of: rhs).reversed())
        let maxColumns = max(lhsReversed.count, rhsReversed.count)

        var carry = 0
        var incomingCarries: [Int?] = []
        var steps: [String] = []

        for i in 0..<maxColumns {
            let left = i < lhsReversed.count ? lhsReversed[i] : 0
            let right = i < rhsReversed.count ? rhsReversed[i] : 0
            incomingCarries.append(carry > 0 ? carry : nil)

            let sum = left + right + carry
            let digit = sum % 10
            let newCarry = sum / 10
            if newCarry > 0 {
                steps.append("\(left) + \(right) + \(carry) = \(sum), write \(digit), carry \(newCarry).")
            } else {
                steps.append("\(left) + \(right) + \(carry) = \(sum), write \(digit).")
            }
            carry = newCarry
        }

        if carry > 0 {
            steps.append("Place the final carried \(carry) at the front.")
        }

        let result = lhs + rhs
        let width = max(digits(of: lhs).count, digits(of: rhs).count, digits(of: result).count)

        return (
            lhsDigits: paddedDigits(of: lhs, width: width),
            rhsDigits: paddedDigits(of: rhs, width: width),
            resultDigits: paddedDigits(of: result, width: width),
            carryDigits: fromReversedColumns(incomingCarries, width: width),
            steps: steps
        )
    }

    private static func buildSubtraction(lhs: Int, rhs: Int) -> (lhsDigits: [Int?], rhsDigits: [Int?], resultDigits: [Int?], borrowAdjustments: [BorrowAdjustment?], steps: [String]) {
        let result = lhs - rhs
        let width = max(digits(of: lhs).count, digits(of: rhs).count, digits(of: result).count)

        let lhsOriginal = paddedIntDigits(of: lhs, width: width)
        let rhsDigits = paddedIntDigits(of: rhs, width: width)
        var workingTop = lhsOriginal
        var borrowAdjustments = Array<BorrowAdjustment?>(repeating: nil, count: width)
        var steps: [String] = []

        for i in stride(from: width - 1, through: 0, by: -1) {
            let subtrahend = rhsDigits[i]
            if workingTop[i] < subtrahend {
                var source = i - 1
                while source >= 0 && workingTop[source] == 0 {
                    source -= 1
                }

                if source >= 0 {
                    let oldSource = workingTop[source]
                    workingTop[source] -= 1
                    borrowAdjustments[source] = BorrowAdjustment(oldDigit: oldSource, newDigit: workingTop[source])

                    if source + 1 <= i - 1 {
                        for index in (source + 1)...(i - 1) {
                            let oldValue = workingTop[index]
                            workingTop[index] = 9
                            borrowAdjustments[index] = BorrowAdjustment(oldDigit: oldValue, newDigit: 9)
                        }
                    }

                    workingTop[i] += 10
                }
            }

            let difference = workingTop[i] - subtrahend
            steps.append("\(workingTop[i]) - \(subtrahend) = \(difference).")
        }

        return (
            lhsDigits: paddedDigits(of: lhs, width: width),
            rhsDigits: paddedDigits(of: rhs, width: width),
            resultDigits: paddedDigits(of: result, width: width),
            borrowAdjustments: borrowAdjustments,
            steps: steps
        )
    }

    private static func wholeNumber(_ value: Double) -> Int? {
        let rounded = value.rounded()
        guard abs(rounded - value) < 0.000001 else { return nil }
        let intValue = Int(rounded)
        return intValue >= 0 ? intValue : nil
    }

    private static func digits(of value: Int) -> [Int] {
        let raw = Array(String(value)).compactMap { $0.wholeNumberValue }
        return raw.isEmpty ? [0] : raw
    }

    private static func paddedDigits(of value: Int, width: Int) -> [Int?] {
        let raw = digits(of: value).map(Optional.some)
        let padCount = max(0, width - raw.count)
        return Array(repeating: nil, count: padCount) + raw
    }

    private static func paddedIntDigits(of value: Int, width: Int) -> [Int] {
        let raw = digits(of: value)
        let padCount = max(0, width - raw.count)
        return Array(repeating: 0, count: padCount) + raw
    }

    private static func fromReversedColumns(_ reversedColumns: [Int?], width: Int) -> [Int?] {
        var result = Array<Int?>(repeating: nil, count: width)
        for index in 0..<min(reversedColumns.count, width) {
            result[width - 1 - index] = reversedColumns[index]
        }
        return result
    }
}

private struct BorrowAdjustment {
    let oldDigit: Int
    let newDigit: Int
}
