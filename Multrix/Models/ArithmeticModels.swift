//
//  ArithmeticModels.swift
//  Multrix
//

import Foundation

enum ArithmeticOperation: String, CaseIterable {
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

enum ArithmeticDisplayMode: String, CaseIterable {
    case full
    case thousands
    case millions

    var title: String {
        switch self {
        case .full: return "Full"
        case .thousands: return "K"
        case .millions: return "M"
        }
    }

    var suffix: String {
        switch self {
        case .full: return ""
        case .thousands: return "K"
        case .millions: return "M"
        }
    }
}

struct ArithmeticProblemSettings {
    var minOperandValue: Double = 1
    var maxOperandValue: Double = 999
    var lowRangeFraction: Double = 0.05
    var lowRangeProbability: Double = 0.9
    var maxAnswerValue: Double = 999_999
    var maxAttempts: Int = 80
    var lowRangeSkewPower: Double = 2.2
    var decimalProbability: Double = 0.35
    var decimalStep: Double = 0.1
}

struct ArithmeticProblem: Identifiable {
    let id = UUID()
    let lhs: Double
    let rhs: Double
    let operation: ArithmeticOperation
    let answer: Double

    func lhsDisplay(mode: ArithmeticDisplayMode) -> String {
        ArithmeticNumberFormatter.formatOperand(lhs, mode: mode)
    }

    func rhsDisplay(mode: ArithmeticDisplayMode) -> String {
        ArithmeticNumberFormatter.formatOperand(rhs, mode: mode)
    }

    func answerDisplay(mode: ArithmeticDisplayMode) -> String {
        ArithmeticNumberFormatter.formatAnswer(answer, mode: mode)
    }
}

enum ArithmeticNumberFormatter {
    private static let epsilon = 0.000001

    static func formatOperand(_ value: Double, mode: ArithmeticDisplayMode) -> String {
        let formatted = formatMantissa(value, maxFractionDigits: 1)
        return mode == .full ? formatted : formatted + mode.suffix
    }

    static func formatAnswer(_ value: Double, mode: ArithmeticDisplayMode) -> String {
        let formatted = formatMantissa(value, maxFractionDigits: 2)
        return mode == .full ? formatted : formatted + mode.suffix
    }

    private static func formatMantissa(_ value: Double, maxFractionDigits: Int) -> String {
        let sign = value < 0 ? "-" : ""
        let absValue = abs(value)

        if isNearlyInteger(absValue) || maxFractionDigits == 0 {
            let intValue = Int(absValue.rounded())
            return sign + intValue.formatted(.number.grouping(.automatic))
        }

        return sign + absValue.formatted(
            .number
                .grouping(.automatic)
                .precision(.fractionLength(0...maxFractionDigits))
        )
    }

    private static func isNearlyInteger(_ value: Double) -> Bool {
        abs(value - value.rounded()) < epsilon
    }
}

struct ArithmeticProblemGenerator {
    private static let epsilon = 0.000001

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
        settings: ArithmeticProblemSettings,
        allowDecimals: Bool = true
    ) -> Double {
        let t = pow(Double.random(in: 0...1), skewPower)
        let raw = range.lowerBound + t * (range.upperBound - range.lowerBound)
        return snapValue(raw, allowDecimals: allowDecimals, settings: settings)
    }

    private static func snapValue(
        _ value: Double,
        allowDecimals: Bool,
        settings: ArithmeticProblemSettings
    ) -> Double {
        let minValue = settings.minOperandValue
        let maxValue = settings.maxOperandValue
        var clamped = min(max(value, minValue), maxValue)

        if allowDecimals, Double.random(in: 0...1) < settings.decimalProbability {
            let step = max(settings.decimalStep, 0.01)
            clamped = (clamped / step).rounded() * step
        } else {
            clamped = clamped.rounded()
        }

        if clamped < minValue { clamped = minValue }
        if clamped > maxValue { clamped = maxValue }
        return clamped
    }

    private static func isDisplayable(_ value: Double, settings: ArithmeticProblemSettings) -> Bool {
        let minValue = settings.minOperandValue
        let maxValue = settings.maxOperandValue
        if value < minValue || value > maxValue { return false }

        if isNearlyInteger(value) { return true }
        let step = max(settings.decimalStep, 0.01)
        return isMultiple(value, step: step)
    }

    private static func isMultiple(_ value: Double, step: Double) -> Bool {
        let scaled = (value / step).rounded() * step
        return abs(scaled - value) < epsilon
    }

    private static func isNearlyInteger(_ value: Double) -> Bool {
        abs(value - value.rounded()) < epsilon
    }
}
