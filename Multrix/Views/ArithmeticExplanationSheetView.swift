//
//  ArithmeticExplanationSheetView.swift
//  Multrix
//

import Foundation
import SwiftUI

enum ArithmeticExplanationSupport {
    static func canExplain(_ problem: ArithmeticProblem) -> Bool {
        guard problem.lhs.isFinite, problem.rhs.isFinite, problem.answer.isFinite else {
            return false
        }

        if problem.lhs < 0 || problem.rhs < 0 { return false }

        switch problem.operation {
        case .addition:
            return true
        case .subtraction:
            return problem.lhs >= problem.rhs
        case .multiplication:
            return true
        case .division:
            return problem.rhs != 0
        }
    }
}

struct ArithmeticExplanationSheetView: View {
    let problem: ArithmeticProblem

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    expressionHeader

                    explanationBody
                }
                .padding()
            }
            .navigationTitle("Explanation")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var explanationBody: some View {
        switch problem.operation {
        case .addition, .subtraction:
            if let work = AddSubWork.build(for: problem) {
                AddSubExplanationContent(problem: problem, work: work)
            } else {
                unsupportedView
            }
        case .multiplication:
            if let work = MultiplicationWork.build(for: problem) {
                MultiplicationExplanationContent(problem: problem, work: work)
            } else {
                unsupportedView
            }
        case .division:
            if let work = DivisionWork.build(for: problem) {
                DivisionExplanationContent(problem: problem, work: work)
            } else {
                unsupportedView
            }
        }
    }

    private var expressionHeader: some View {
        HStack(spacing: 8) {
            Text(ArithmeticNumberFormatter.formatOperand(problem.lhs, mode: .full))
            Text(problem.operation.symbol)
                .foregroundStyle(problem.operation.operatorColor)
            Text(ArithmeticNumberFormatter.formatOperand(problem.rhs, mode: .full))
            Text("=")
            Text(ArithmeticNumberFormatter.formatAnswer(problem.answer, mode: .full))
        }
        .font(.title2.weight(.bold))
        .monospacedDigit()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var unsupportedView: some View {
        Text("This problem cannot be shown in step-by-step notation yet.")
            .foregroundStyle(.secondary)
    }
}

private struct AddSubExplanationContent: View {
    let problem: ArithmeticProblem
    let work: AddSubWork

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            explanationCard {
                AddSubNotationView(work: work, operation: problem.operation)
            }

            ExplanationStepsView(steps: work.steps)
        }
    }
}

private struct AddSubNotationView: View {
    let work: AddSubWork
    let operation: ArithmeticOperation

    private let cellWidth: CGFloat = 24
    private let symbolWidth: CGFloat = 24
    private let digitFont = Font.system(size: 34, weight: .bold, design: .monospaced)
    private let smallFont = Font.system(size: 16, weight: .semibold, design: .monospaced)

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if operation == .addition {
                annotationRow(values: work.carryTargets, color: .green)
            } else {
                if !work.borrowReceivers.isEmpty {
                    annotationRow(values: work.borrowReceiverMarkers, color: .orange)
                }
                if !work.adjustedDigits.isEmpty {
                    annotationRow(values: work.adjustedDigits, color: .red)
                }
            }

            operandRow(digits: work.lhsDigits, strikethroughColumns: work.crossedColumns)
            operatorOperandRow(symbol: operation.symbol, symbolColor: operation.operatorColor, digits: work.rhsDigits)

            HStack(spacing: 0) {
                Spacer().frame(width: symbolWidth)
                Rectangle()
                    .fill(Color.primary)
                    .frame(width: CGFloat(work.columns.count) * cellWidth, height: 2)
            }

            operandRow(digits: work.resultDigits, strikethroughColumns: [])
        }
    }

    @ViewBuilder
    private func annotationRow(values: [Int: Int], color: Color) -> some View {
        HStack(spacing: 0) {
            Spacer().frame(width: symbolWidth)
            ForEach(Array(work.columns.enumerated()), id: \.offset) { _, column in
                switch column {
                case .digit(let index):
                    if let value = values[index] {
                        Text("\(value)")
                            .foregroundStyle(color)
                            .font(smallFont)
                            .frame(width: cellWidth)
                    } else {
                        Text(" ")
                            .font(smallFont)
                            .frame(width: cellWidth)
                    }
                case .decimalPoint:
                    Text(" ")
                        .font(smallFont)
                        .frame(width: cellWidth)
                }
            }
        }
    }

    @ViewBuilder
    private func operandRow(digits: [Int], strikethroughColumns: Set<Int>) -> some View {
        HStack(spacing: 0) {
            Spacer().frame(width: symbolWidth)
            ForEach(Array(work.columns.enumerated()), id: \.offset) { _, column in
                switch column {
                case .digit(let index):
                    Text("\(digits[index])")
                        .font(digitFont)
                        .frame(width: cellWidth)
                        .strikethrough(strikethroughColumns.contains(index), color: .red)
                case .decimalPoint:
                    Text(".")
                        .font(digitFont)
                        .frame(width: cellWidth)
                }
            }
        }
    }

    @ViewBuilder
    private func operatorOperandRow(symbol: String, symbolColor: Color, digits: [Int]) -> some View {
        HStack(spacing: 0) {
            Text(symbol)
                .font(digitFont)
                .foregroundStyle(symbolColor)
                .frame(width: symbolWidth)

            ForEach(Array(work.columns.enumerated()), id: \.offset) { _, column in
                switch column {
                case .digit(let index):
                    Text("\(digits[index])")
                        .font(digitFont)
                        .frame(width: cellWidth)
                case .decimalPoint:
                    Text(".")
                        .font(digitFont)
                        .frame(width: cellWidth)
                }
            }
        }
    }
}

private struct MultiplicationExplanationContent: View {
    let problem: ArithmeticProblem
    let work: MultiplicationWork

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            explanationCard {
                MultiplicationNotationView(work: work)
            }

            ExplanationStepsView(steps: work.steps)
        }
    }
}

private struct MultiplicationNotationView: View {
    let work: MultiplicationWork

    private let charWidth: CGFloat = 22
    private let symbolWidth: CGFloat = 24
    private let digitFont = Font.system(size: 32, weight: .bold, design: .monospaced)

    private var contentWidth: CGFloat {
        CGFloat(maxCharacterCount) * charWidth
    }

    private var maxCharacterCount: Int {
        var allRows = [work.lhsText, work.rhsText, work.resultText]
        allRows.append(contentsOf: work.partialRows)
        return max(allRows.map(\.count).max() ?? 1, 1)
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            rowWithSpacer(text: work.lhsText)
            rowWithOperator(symbol: "×", color: .blue, text: work.rhsText)
            horizontalLine

            ForEach(Array(work.partialRows.enumerated()), id: \.offset) { _, row in
                rowWithSpacer(text: row)
            }

            if work.partialRows.count > 1 {
                horizontalLine
            }

            rowWithSpacer(text: work.resultText)
        }
    }

    @ViewBuilder
    private func rowWithSpacer(text: String) -> some View {
        HStack(spacing: 0) {
            Spacer().frame(width: symbolWidth)
            Text(text)
                .font(digitFont)
                .frame(width: contentWidth, alignment: .trailing)
        }
    }

    @ViewBuilder
    private func rowWithOperator(symbol: String, color: Color, text: String) -> some View {
        HStack(spacing: 0) {
            Text(symbol)
                .font(digitFont)
                .foregroundStyle(color)
                .frame(width: symbolWidth)

            Text(text)
                .font(digitFont)
                .frame(width: contentWidth, alignment: .trailing)
        }
    }

    private var horizontalLine: some View {
        HStack(spacing: 0) {
            Spacer().frame(width: symbolWidth)
            Rectangle()
                .fill(Color.primary)
                .frame(width: contentWidth, height: 2)
        }
    }
}

private struct DivisionExplanationContent: View {
    let problem: ArithmeticProblem
    let work: DivisionWork

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            explanationCard {
                DivisionNotationView(work: work)
            }

            ExplanationStepsView(steps: work.steps)
        }
    }
}

private struct DivisionNotationView: View {
    let work: DivisionWork

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(work.notationLines.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .monospacedDigit()
    }
}

private struct ExplanationStepsView: View {
    let steps: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Steps")
                .font(.headline)

            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(index + 1).")
                        .fontWeight(.semibold)
                    Text(step)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

private enum AddSubColumn {
    case digit(Int)
    case decimalPoint
}

private struct AddSubWork {
    let columns: [AddSubColumn]
    let lhsDigits: [Int]
    let rhsDigits: [Int]
    let resultDigits: [Int]
    let carryTargets: [Int: Int]
    let borrowReceivers: Set<Int>
    let crossedColumns: Set<Int>
    let adjustedDigits: [Int: Int]
    let steps: [String]

    var borrowReceiverMarkers: [Int: Int] {
        borrowReceivers.reduce(into: [:]) { partial, index in
            partial[index] = 1
        }
    }

    static func build(for problem: ArithmeticProblem) -> AddSubWork? {
        let lhsFraction = ExplanationMath.fractionDigits(for: problem.lhs)
        let rhsFraction = ExplanationMath.fractionDigits(for: problem.rhs)
        let fractionDigits = max(lhsFraction, rhsFraction)
        let scale = ExplanationMath.pow10(fractionDigits)

        let lhsScaled = ExplanationMath.scaledInt(problem.lhs, fractionDigits: fractionDigits)
        let rhsScaled = ExplanationMath.scaledInt(problem.rhs, fractionDigits: fractionDigits)

        guard lhsScaled >= 0, rhsScaled >= 0 else { return nil }

        let rawResult: Int
        switch problem.operation {
        case .addition:
            rawResult = lhsScaled + rhsScaled
        case .subtraction:
            guard lhsScaled >= rhsScaled else { return nil }
            rawResult = lhsScaled - rhsScaled
        default:
            return nil
        }

        let totalDigits = max(
            ExplanationMath.digitCount(of: lhsScaled),
            ExplanationMath.digitCount(of: rhsScaled),
            ExplanationMath.digitCount(of: rawResult),
            fractionDigits + 1
        )

        let lhsDigits = ExplanationMath.digits(of: lhsScaled, width: totalDigits)
        let rhsDigits = ExplanationMath.digits(of: rhsScaled, width: totalDigits)

        let resultDigits: [Int]
        let carryTargets: [Int: Int]
        let borrowReceivers: Set<Int>
        let crossedColumns: Set<Int>
        let adjustedDigits: [Int: Int]
        let steps: [String]

        switch problem.operation {
        case .addition:
            let addition = buildAddition(lhsDigits: lhsDigits, rhsDigits: rhsDigits)
            resultDigits = addition.resultDigits
            carryTargets = addition.carryTargets
            borrowReceivers = []
            crossedColumns = []
            adjustedDigits = [:]
            steps = additionSteps(
                carryTargets: carryTargets,
                fractionDigits: fractionDigits,
                lhs: problem.lhs,
                rhs: problem.rhs,
                scale: scale
            )
        case .subtraction:
            let subtraction = buildSubtraction(lhsDigits: lhsDigits, rhsDigits: rhsDigits)
            resultDigits = subtraction.resultDigits
            carryTargets = [:]
            borrowReceivers = subtraction.borrowReceivers
            crossedColumns = subtraction.crossedColumns
            adjustedDigits = subtraction.adjustedDigits
            steps = subtractionSteps(
                borrowReceivers: borrowReceivers,
                fractionDigits: fractionDigits,
                lhs: problem.lhs,
                rhs: problem.rhs,
                scale: scale
            )
        default:
            return nil
        }

        let columns = buildColumns(totalDigits: totalDigits, fractionDigits: fractionDigits)

        return AddSubWork(
            columns: columns,
            lhsDigits: lhsDigits,
            rhsDigits: rhsDigits,
            resultDigits: resultDigits,
            carryTargets: carryTargets,
            borrowReceivers: borrowReceivers,
            crossedColumns: crossedColumns,
            adjustedDigits: adjustedDigits,
            steps: steps
        )
    }

    private static func buildAddition(lhsDigits: [Int], rhsDigits: [Int]) -> AdditionBuildResult {
        let width = lhsDigits.count
        var result = Array(repeating: 0, count: width)
        var carries: [Int: Int] = [:]
        var carry = 0

        for index in 0..<width {
            let sum = lhsDigits[index] + rhsDigits[index] + carry
            result[index] = sum % 10
            let nextCarry = sum / 10
            if nextCarry > 0, index + 1 < width {
                carries[index + 1] = nextCarry
            }
            carry = nextCarry
        }

        return AdditionBuildResult(resultDigits: result, carryTargets: carries)
    }

    private static func buildSubtraction(lhsDigits: [Int], rhsDigits: [Int]) -> SubtractionBuildResult {
        let width = lhsDigits.count
        var working = lhsDigits
        var result = Array(repeating: 0, count: width)
        var borrowReceivers: Set<Int> = []
        var crossedColumns: Set<Int> = []

        for index in 0..<width {
            if working[index] < rhsDigits[index] {
                var donor = index + 1
                while donor < width, working[donor] == 0 {
                    donor += 1
                }

                if donor >= width { continue }

                working[donor] -= 1
                crossedColumns.insert(donor)

                if donor - index > 1 {
                    for intermediate in stride(from: donor - 1, through: index + 1, by: -1) {
                        working[intermediate] += 9
                        crossedColumns.insert(intermediate)
                    }
                }

                working[index] += 10
                borrowReceivers.insert(index)
            }

            result[index] = working[index] - rhsDigits[index]
        }

        let adjustedDigits = crossedColumns.reduce(into: [:]) { partial, index in
            partial[index] = working[index]
        }

        return SubtractionBuildResult(
            resultDigits: result,
            borrowReceivers: borrowReceivers,
            crossedColumns: crossedColumns,
            adjustedDigits: adjustedDigits
        )
    }

    private static func buildColumns(totalDigits: Int, fractionDigits: Int) -> [AddSubColumn] {
        var columns: [AddSubColumn] = []

        for index in stride(from: totalDigits - 1, through: 0, by: -1) {
            columns.append(.digit(index))
            if fractionDigits > 0, index == fractionDigits {
                columns.append(.decimalPoint)
            }
        }

        return columns
    }

    private static func additionSteps(
        carryTargets: [Int: Int],
        fractionDigits: Int,
        lhs: Double,
        rhs: Double,
        scale: Int
    ) -> [String] {
        var steps: [String] = []

        if fractionDigits > 0 {
            let lhsText = ExplanationMath.fixedDecimalString(lhs, fractionDigits: fractionDigits)
            let rhsText = ExplanationMath.fixedDecimalString(rhs, fractionDigits: fractionDigits)
            steps.append("Align decimal points so every column has the same place value: \(lhsText) and \(rhsText).")
        }

        steps.append("Add from right to left, one column at a time.")

        if !carryTargets.isEmpty {
            steps.append("When a column is 10 or more, write the ones digit and carry the extra 1 to the next column.")
        }

        let placeValue = fractionDigits > 0 ? " (using tenths/hundredths as needed)" : ""
        steps.append("Read the total below the line\(placeValue).")

        if fractionDigits > 0, scale > 1 {
            steps.append("The decimal stays aligned all the way through the sum.")
        }

        return steps
    }

    private static func subtractionSteps(
        borrowReceivers: Set<Int>,
        fractionDigits: Int,
        lhs: Double,
        rhs: Double,
        scale: Int
    ) -> [String] {
        var steps: [String] = []

        if fractionDigits > 0 {
            let lhsText = ExplanationMath.fixedDecimalString(lhs, fractionDigits: fractionDigits)
            let rhsText = ExplanationMath.fixedDecimalString(rhs, fractionDigits: fractionDigits)
            steps.append("Align decimal points first: \(lhsText) and \(rhsText).")
        }

        steps.append("Subtract from right to left, one column at a time.")

        if !borrowReceivers.isEmpty {
            steps.append("If the top digit is smaller, borrow 1 from the next column to the left. The borrowed-from digit is crossed out and reduced.")
        }

        let placeValue = fractionDigits > 0 ? "with decimal places kept in alignment" : ""
        steps.append("Write the difference below the line \(placeValue).".trimmingCharacters(in: .whitespaces))

        if fractionDigits > 0, scale > 1 {
            steps.append("Borrowing can move across the decimal point just like any other place-value column.")
        }

        return steps
    }

    private struct AdditionBuildResult {
        let resultDigits: [Int]
        let carryTargets: [Int: Int]
    }

    private struct SubtractionBuildResult {
        let resultDigits: [Int]
        let borrowReceivers: Set<Int>
        let crossedColumns: Set<Int>
        let adjustedDigits: [Int: Int]
    }
}

private struct MultiplicationWork {
    let lhsText: String
    let rhsText: String
    let partialRows: [String]
    let resultText: String
    let steps: [String]

    static func build(for problem: ArithmeticProblem) -> MultiplicationWork? {
        guard problem.operation == .multiplication else { return nil }

        let lhsFraction = ExplanationMath.fractionDigits(for: problem.lhs)
        let rhsFraction = ExplanationMath.fractionDigits(for: problem.rhs)

        let lhsInteger = ExplanationMath.scaledInt(problem.lhs, fractionDigits: lhsFraction)
        let rhsInteger = ExplanationMath.scaledInt(problem.rhs, fractionDigits: rhsFraction)

        guard lhsInteger >= 0, rhsInteger >= 0 else { return nil }

        let rhsDigits = ExplanationMath.compactDigits(of: rhsInteger)
        let partialRows: [String]

        if rhsDigits.isEmpty {
            partialRows = ["0"]
        } else {
            partialRows = rhsDigits.enumerated().map { offset, digit in
                let partial = lhsInteger * digit * ExplanationMath.pow10(offset)
                return String(partial)
            }
        }

        let fractionTotal = lhsFraction + rhsFraction
        let rawProduct = lhsInteger * rhsInteger

        let steps = multiplicationSteps(
            lhs: problem.lhs,
            rhs: problem.rhs,
            lhsInteger: lhsInteger,
            rhsInteger: rhsInteger,
            rhsDigits: rhsDigits,
            fractionTotal: fractionTotal
        )

        return MultiplicationWork(
            lhsText: ExplanationMath.fixedDecimalString(problem.lhs, fractionDigits: lhsFraction),
            rhsText: ExplanationMath.fixedDecimalString(problem.rhs, fractionDigits: rhsFraction),
            partialRows: partialRows,
            resultText: ExplanationMath.scaledIntegerString(rawProduct, fractionDigits: fractionTotal),
            steps: steps
        )
    }

    private static func multiplicationSteps(
        lhs: Double,
        rhs: Double,
        lhsInteger: Int,
        rhsInteger: Int,
        rhsDigits: [Int],
        fractionTotal: Int
    ) -> [String] {
        var steps: [String] = []

        if fractionTotal > 0 {
            steps.append("Ignore decimals first: multiply \(lhsInteger) by \(rhsInteger).")
        } else {
            steps.append("Multiply from right to left, creating a partial product for each digit in the bottom number.")
        }

        if rhsDigits.count > 1 {
            steps.append("Each new partial product shifts one place left (shown as trailing zeros).")
        }

        steps.append("Add all partial products to get the raw product.")

        if fractionTotal > 0 {
            let lhsPlaces = ExplanationMath.fractionDigits(for: lhs)
            let rhsPlaces = ExplanationMath.fractionDigits(for: rhs)
            steps.append("Put the decimal back with \(lhsPlaces + rhsPlaces) total decimal place(s) (\(lhsPlaces) from the top number and \(rhsPlaces) from the bottom number).")
        }

        return steps
    }
}

private struct DivisionWork {
    let notationLines: [String]
    let steps: [String]

    static func build(for problem: ArithmeticProblem) -> DivisionWork? {
        guard problem.operation == .division, problem.rhs != 0 else {
            return nil
        }

        let lhsFraction = ExplanationMath.fractionDigits(for: problem.lhs)
        let rhsFraction = ExplanationMath.fractionDigits(for: problem.rhs)
        let normalizeShift = max(lhsFraction, rhsFraction)

        let normalizedDividend = ExplanationMath.scaledInt(problem.lhs, fractionDigits: normalizeShift)
        let normalizedDivisor = ExplanationMath.scaledInt(problem.rhs, fractionDigits: normalizeShift)

        guard normalizedDivisor > 0, normalizedDividend >= 0 else {
            return nil
        }

        let requiredFractionDigits = ExplanationMath.fractionDigits(for: problem.answer)
        let longDivision = buildLongDivision(
            dividend: normalizedDividend,
            divisor: normalizedDivisor,
            maxFractionDigits: max(requiredFractionDigits, 3)
        )

        let notationLines = buildNotationLines(
            divisorText: String(normalizedDivisor),
            dividendText: String(normalizedDividend),
            quotientText: longDivision.quotientText,
            steps: longDivision.steps
        )

        var steps: [String] = []

        if normalizeShift > 0 {
            let lhsText = ExplanationMath.fixedDecimalString(problem.lhs, fractionDigits: lhsFraction)
            let rhsText = ExplanationMath.fixedDecimalString(problem.rhs, fractionDigits: rhsFraction)
            steps.append("Shift both numbers right by \(normalizeShift) place(s) to remove decimals: \(lhsText) ÷ \(rhsText) becomes \(normalizedDividend) ÷ \(normalizedDivisor).")
        }

        if longDivision.steps.isEmpty {
            steps.append("The divisor goes into the dividend exactly, so the quotient is read directly.")
        } else {
            steps.append(contentsOf: longDivision.steps.prefix(4).enumerated().map { index, item in
                "Long division step \(index + 1): \(item)"
            })

            if longDivision.steps.count > 4 {
                steps.append("Continue the same divide-subtract-bring down pattern until the remainder is 0.")
            }
        }

        let shownAnswer = ArithmeticNumberFormatter.formatAnswer(problem.answer, mode: .full)
        steps.append("The quotient is \(shownAnswer).")

        return DivisionWork(notationLines: notationLines, steps: steps)
    }

    private static func buildLongDivision(
        dividend: Int,
        divisor: Int,
        maxFractionDigits: Int
    ) -> (quotientText: String, steps: [String]) {
        let integerDigits = String(dividend).compactMap { $0.wholeNumberValue }
        var remainder = 0
        var quotient = ""
        var hasStarted = false
        var consumedDigits = 0
        var stepDetails: [LongDivisionStep] = []

        for digit in integerDigits {
            remainder = remainder * 10 + digit
            consumedDigits += 1

            if remainder < divisor {
                if hasStarted {
                    quotient.append("0")
                }
                continue
            }

            let quotientDigit = remainder / divisor
            let subtraction = quotientDigit * divisor
            let nextRemainder = remainder - subtraction

            quotient.append(String(quotientDigit))
            hasStarted = true

            stepDetails.append(
                LongDivisionStep(
                    consumedDigits: consumedDigits,
                    workingValue: remainder,
                    quotientDigit: quotientDigit,
                    subtraction: subtraction,
                    remainder: nextRemainder
                )
            )

            remainder = nextRemainder
        }

        if !hasStarted {
            quotient = "0"
        }

        if remainder != 0 {
            quotient.append(".")
        }

        var fractionalDigits = 0
        while remainder != 0, fractionalDigits < maxFractionDigits {
            remainder *= 10
            fractionalDigits += 1

            let quotientDigit = remainder / divisor
            let subtraction = quotientDigit * divisor
            let nextRemainder = remainder - subtraction

            quotient.append(String(quotientDigit))

            stepDetails.append(
                LongDivisionStep(
                    consumedDigits: integerDigits.count + fractionalDigits,
                    workingValue: remainder,
                    quotientDigit: quotientDigit,
                    subtraction: subtraction,
                    remainder: nextRemainder
                )
            )

            remainder = nextRemainder
        }

        let quotientText = ExplanationMath.trimTrailingZeroes(in: quotient)

        let readableSteps = stepDetails.map { step in
            "\(divisor) goes into \(step.workingValue) \(step.quotientDigit) time(s), subtract \(step.subtraction), remainder \(step.remainder)."
        }

        return (quotientText, readableSteps)
    }

    private static func buildNotationLines(
        divisorText: String,
        dividendText: String,
        quotientText: String,
        steps: [String]
    ) -> [String] {
        var lines: [String] = []
        let baseOffset = divisorText.count + 3

        lines.append(String(repeating: " ", count: baseOffset) + quotientText)
        lines.append("\(divisorText) ) \(dividendText)")

        // A compact textual guide under the long-division setup so each subtraction is visible.
        for step in steps.prefix(3) {
            lines.append("  \(step)")
        }

        return lines
    }

    private struct LongDivisionStep {
        let consumedDigits: Int
        let workingValue: Int
        let quotientDigit: Int
        let subtraction: Int
        let remainder: Int
    }
}

private enum ExplanationMath {
    private static let epsilon = 0.000_001

    static func fractionDigits(for value: Double, maxDigits: Int = 3) -> Int {
        let absolute = abs(value)
        for digits in 0...maxDigits {
            let scaled = absolute * pow(10, Double(digits))
            if abs(scaled - scaled.rounded()) < epsilon {
                return digits
            }
        }
        return maxDigits
    }

    static func scaledInt(_ value: Double, fractionDigits: Int) -> Int {
        let factor = Double(pow10(fractionDigits))
        return Int((value * factor).rounded())
    }

    static func digits(of value: Int, width: Int) -> [Int] {
        let count = max(width, 1)
        var digits = Array(repeating: 0, count: count)
        var remaining = abs(value)

        for index in 0..<count {
            digits[index] = remaining % 10
            remaining /= 10
        }

        return digits
    }

    static func compactDigits(of value: Int) -> [Int] {
        let absolute = abs(value)
        if absolute == 0 { return [0] }

        var digits: [Int] = []
        var remaining = absolute
        while remaining > 0 {
            digits.append(remaining % 10)
            remaining /= 10
        }

        return digits
    }

    static func digitCount(of value: Int) -> Int {
        let absolute = abs(value)
        if absolute == 0 { return 1 }
        return String(absolute).count
    }

    static func pow10(_ exponent: Int) -> Int {
        guard exponent > 0 else { return 1 }
        return Int(pow(10, Double(exponent)))
    }

    static func fixedDecimalString(_ value: Double, fractionDigits: Int) -> String {
        if fractionDigits == 0 {
            return String(Int(value.rounded()))
        }

        let rounded = Double(scaledInt(value, fractionDigits: fractionDigits)) / Double(pow10(fractionDigits))
        return String(format: "%0.*f", fractionDigits, rounded)
    }

    static func scaledIntegerString(_ scaledValue: Int, fractionDigits: Int) -> String {
        let sign = scaledValue < 0 ? "-" : ""
        let absoluteValue = abs(scaledValue)

        guard fractionDigits > 0 else {
            return sign + String(absoluteValue)
        }

        var raw = String(absoluteValue)
        if raw.count <= fractionDigits {
            raw = String(repeating: "0", count: fractionDigits - raw.count + 1) + raw
        }

        let splitIndex = raw.index(raw.endIndex, offsetBy: -fractionDigits)
        let integerPart = String(raw[..<splitIndex])
        let fractionalPart = String(raw[splitIndex...])

        return sign + integerPart + "." + fractionalPart
    }

    static func trimTrailingZeroes(in quotient: String) -> String {
        guard quotient.contains(".") else { return quotient }

        var output = quotient
        while output.last == "0" {
            output.removeLast()
        }
        if output.last == "." {
            output.removeLast()
        }
        return output
    }
}

@ViewBuilder
private func explanationCard<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        content()
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.gray.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: 14))
}
