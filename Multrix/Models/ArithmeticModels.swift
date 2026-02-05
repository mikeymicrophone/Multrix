//
//  ArithmeticModels.swift
//  Multrix
//

import Foundation

enum ArithmeticOperation: CaseIterable {
    case addition
    case subtraction
    case multiplication
    case division

    var symbol: String {
        switch self {
        case .addition: return "+"
        case .subtraction: return "-"
        case .multiplication: return "×"
        case .division: return "÷"
        }
    }

    func apply(lhs: Double, rhs: Double) -> Double {
        switch self {
        case .addition:
            return lhs + rhs
        case .subtraction:
            return lhs - rhs
        case .multiplication:
            return lhs * rhs
        case .division:
            return lhs / rhs
        }
    }
}

struct ArithmeticProblemSettings {
    var minOperandValue: Double = 1
    var maxOperandValue: Double = 9_900_000
    var lowRangeFraction: Double = 0.05
    var lowRangeProbability: Double = 0.9
    var maxAnswerValue: Double = 999_000_000
    var maxAttempts: Int = 80
    var lowRangeSkewPower: Double = 2.2
}

struct ArithmeticProblem: Identifiable {
    let id = UUID()
    let lhs: Double
    let rhs: Double
    let operation: ArithmeticOperation
    let answer: Double

    var lhsDisplay: String {
        ArithmeticNumberFormatter.formatOperand(lhs)
    }

    var rhsDisplay: String {
        ArithmeticNumberFormatter.formatOperand(rhs)
    }

    var answerDisplay: String {
        ArithmeticNumberFormatter.formatAnswer(answer)
    }
}

enum ArithmeticNumberFormatter {
    private static let epsilon = 0.000001

    static func formatOperand(_ value: Double) -> String {
        let sign = value < 0 ? "-" : ""
        let absValue = abs(value)

        if absValue >= 1_000_000 {
            return sign + formatAbbreviated(absValue / 1_000_000, suffix: "M")
        }
        if absValue >= 1_000 {
            return sign + formatAbbreviated(absValue / 1_000, suffix: "K")
        }
        return sign + String(Int(absValue.rounded()))
    }

    static func formatAnswer(_ value: Double) -> String {
        if isNearlyInteger(value) {
            let intValue = Int(value.rounded())
            return intValue.formatted(.number.grouping(.automatic))
        }
        return value.formatted(
            .number
                .grouping(.automatic)
                .precision(.fractionLength(0...2))
        )
    }

    private static func formatAbbreviated(_ value: Double, suffix: String) -> String {
        let rounded = (value * 10).rounded() / 10
        if isNearlyInteger(rounded) {
            return "\(Int(rounded))\(suffix)"
        }
        return String(format: "%.1f%@", rounded, suffix)
    }

    private static func isNearlyInteger(_ value: Double) -> Bool {
        abs(value - value.rounded()) < epsilon
    }
}

struct ArithmeticProblemGenerator {
    private static let smallMax: Double = 999
    private static let thousandMin: Double = 1_000
    private static let thousandMax: Double = 999_900
    private static let thousandStep: Double = 100
    private static let millionMin: Double = 1_000_000
    private static let millionMax: Double = 9_900_000
    private static let millionStep: Double = 100_000

    static func generate(operations: [ArithmeticOperation], settings: ArithmeticProblemSettings) -> ArithmeticProblem {
        let operation = operations.randomElement() ?? .addition
        let useLowRange = Double.random(in: 0...1) < settings.lowRangeProbability

        switch operation {
        case .addition:
            return generateAddition(useLowRange: useLowRange, settings: settings)
        case .subtraction:
            return generateSubtraction(useLowRange: useLowRange, settings: settings)
        case .multiplication:
            return generateMultiplication(useLowRange: useLowRange, settings: settings)
        case .division:
            return generateDivision(useLowRange: useLowRange, settings: settings)
        }
    }

    private static func generateAddition(useLowRange: Bool, settings: ArithmeticProblemSettings) -> ArithmeticProblem {
        let range = operandRange(useLowRange: useLowRange, settings: settings)
        let skewPower = useLowRange ? settings.lowRangeSkewPower : 1.0
        let lhs = randomOperand(in: range, skewPower: skewPower, settings: settings)
        let rhs = randomOperand(in: range, skewPower: skewPower, settings: settings)
        let answer = lhs + rhs
        return ArithmeticProblem(lhs: lhs, rhs: rhs, operation: .addition, answer: answer)
    }

    private static func generateSubtraction(useLowRange: Bool, settings: ArithmeticProblemSettings) -> ArithmeticProblem {
        let range = operandRange(useLowRange: useLowRange, settings: settings)
        let skewPower = useLowRange ? settings.lowRangeSkewPower : 1.0
        var lhs = randomOperand(in: range, skewPower: skewPower, settings: settings)
        var rhs = randomOperand(in: range, skewPower: skewPower, settings: settings)
        if lhs < rhs {
            swap(&lhs, &rhs)
        }
        let answer = lhs - rhs
        return ArithmeticProblem(lhs: lhs, rhs: rhs, operation: .subtraction, answer: answer)
    }

    private static func generateMultiplication(useLowRange: Bool, settings: ArithmeticProblemSettings) -> ArithmeticProblem {
        let range = operandRange(useLowRange: useLowRange, settings: settings)
        let skewPower = useLowRange ? settings.lowRangeSkewPower : 1.0
        for _ in 0..<settings.maxAttempts {
            let lhs = randomOperand(in: range, skewPower: skewPower, settings: settings)
            let rhs = randomOperand(in: range, skewPower: skewPower, settings: settings)
            let answer = lhs * rhs
            if answer <= settings.maxAnswerValue {
                return ArithmeticProblem(lhs: lhs, rhs: rhs, operation: .multiplication, answer: answer)
            }
        }

        let fallbackMax = min(settings.maxOperandValue, sqrt(settings.maxAnswerValue))
        let fallbackRange = settings.minOperandValue...fallbackMax
        let lhs = randomOperand(in: fallbackRange, skewPower: settings.lowRangeSkewPower, settings: settings)
        let rhs = randomOperand(in: fallbackRange, skewPower: settings.lowRangeSkewPower, settings: settings)
        let answer = lhs * rhs
        return ArithmeticProblem(lhs: lhs, rhs: rhs, operation: .multiplication, answer: answer)
    }

    private static func generateDivision(useLowRange: Bool, settings: ArithmeticProblemSettings) -> ArithmeticProblem {
        let range = operandRange(useLowRange: useLowRange, settings: settings)
        let skewPower = useLowRange ? settings.lowRangeSkewPower : 1.0

        for _ in 0..<settings.maxAttempts {
            let quotient = randomOperand(in: range, skewPower: skewPower, settings: settings)
            let divisor = randomOperand(in: range, skewPower: skewPower, settings: settings)
            let dividend = quotient * divisor

            if dividend > settings.maxOperandValue { continue }
            if !isDisplayable(dividend, settings: settings) { continue }

            return ArithmeticProblem(lhs: dividend, rhs: divisor, operation: .division, answer: quotient)
        }

        let fallbackMax = min(settings.maxOperandValue, sqrt(settings.maxOperandValue))
        let fallbackRange = settings.minOperandValue...fallbackMax
        let quotient = randomOperand(in: fallbackRange, skewPower: settings.lowRangeSkewPower, settings: settings)
        let divisor = randomOperand(in: fallbackRange, skewPower: settings.lowRangeSkewPower, settings: settings)
        let dividend = quotient * divisor
        return ArithmeticProblem(lhs: dividend, rhs: divisor, operation: .division, answer: quotient)
    }

    private static func operandRange(useLowRange: Bool, settings: ArithmeticProblemSettings) -> ClosedRange<Double> {
        let minValue = settings.minOperandValue
        let maxValue = settings.maxOperandValue
        let span = maxValue - minValue
        let lowMax = minValue + span * settings.lowRangeFraction
        if useLowRange {
            return minValue...max(lowMax, minValue)
        }
        return minValue...maxValue
    }

    private static func randomOperand(
        in range: ClosedRange<Double>,
        skewPower: Double,
        settings: ArithmeticProblemSettings
    ) -> Double {
        let t = pow(Double.random(in: 0...1), skewPower)
        let raw = range.lowerBound + t * (range.upperBound - range.lowerBound)
        return snapDisplayable(raw, settings: settings)
    }

    private static func snapDisplayable(_ value: Double, settings: ArithmeticProblemSettings) -> Double {
        let minValue = settings.minOperandValue
        let maxValue = settings.maxOperandValue
        let clamped = min(max(value, minValue), maxValue)

        if clamped <= smallMax || maxValue <= smallMax {
            return min(max(clamped.rounded(), minValue), min(maxValue, smallMax))
        }

        if clamped < millionMin || maxValue < millionMin {
            let minBound = max(thousandMin, minValue)
            let maxBound = min(thousandMax, maxValue)
            let stepped = (clamped / thousandStep).rounded() * thousandStep
            return min(max(stepped, minBound), maxBound)
        }

        let minBound = max(millionMin, minValue)
        let maxBound = min(millionMax, maxValue)
        let stepped = (clamped / millionStep).rounded() * millionStep
        return min(max(stepped, minBound), maxBound)
    }

    private static func isDisplayable(_ value: Double, settings: ArithmeticProblemSettings) -> Bool {
        let minValue = settings.minOperandValue
        let maxValue = settings.maxOperandValue
        if value < minValue || value > maxValue { return false }

        if value <= smallMax {
            return isNearlyInteger(value)
        }
        if value < millionMin {
            return isMultiple(value, step: thousandStep)
        }
        return isMultiple(value, step: millionStep)
    }

    private static func isMultiple(_ value: Double, step: Double) -> Bool {
        let scaled = (value / step).rounded() * step
        return abs(scaled - value) < 0.000001
    }

    private static func isNearlyInteger(_ value: Double) -> Bool {
        abs(value - value.rounded()) < 0.000001
    }
}
