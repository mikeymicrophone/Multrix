//
//  ArithmeticHistoryEntry.swift
//  Multrix
//

import Foundation
import SwiftData

@Model
final class ArithmeticHistoryEntry {
    @Attribute(.unique) var id: UUID
    var lhs: Double
    var rhs: Double
    var operationRaw: String
    var displayModeRaw: String?
    var answer: Double
    var createdAt: Date
    var group: String

    init(
        id: UUID = UUID(),
        lhs: Double,
        rhs: Double,
        operation: ArithmeticOperation,
        displayMode: ArithmeticDisplayMode,
        answer: Double,
        group: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.lhs = lhs
        self.rhs = rhs
        self.operationRaw = operation.rawValue
        self.displayModeRaw = displayMode.rawValue
        self.answer = answer
        self.group = group
        self.createdAt = createdAt
    }

    var operation: ArithmeticOperation {
        ArithmeticOperation(rawValue: operationRaw) ?? .addition
    }

    var displayMode: ArithmeticDisplayMode {
        guard let displayModeRaw else { return .full }
        return ArithmeticDisplayMode(rawValue: displayModeRaw) ?? .full
    }

    var lhsDisplay: String {
        ArithmeticNumberFormatter.formatOperand(lhs, mode: displayMode)
    }

    var rhsDisplay: String {
        ArithmeticNumberFormatter.formatOperand(rhs, mode: displayMode)
    }

    var answerDisplay: String {
        ArithmeticNumberFormatter.formatAnswer(answer, mode: displayMode)
    }
}
