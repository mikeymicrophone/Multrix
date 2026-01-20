//
//  PracticeModels.swift
//  Multrix
//

import Foundation

enum OperationType: String, CaseIterable {
    case addition
    case multiplication

    var symbol: String {
        switch self {
        case .addition: return "+"
        case .multiplication: return "×"
        }
    }

    func result(lhs: Int, rhs: Int) -> Int {
        switch self {
        case .addition:
            return lhs + rhs
        case .multiplication:
            return lhs * rhs
        }
    }

    var title: String {
        switch self {
        case .addition: return "Addition"
        case .multiplication: return "Multiplication"
        }
    }
}

enum GuessMode: String, CaseIterable {
    case multipleChoice
    case freeEntry

    var title: String {
        switch self {
        case .multipleChoice: return "Multiple Choice"
        case .freeEntry: return "Free Entry"
        }
    }
}

struct FactKey: Hashable, Identifiable {
    let row: Int
    let col: Int

    var id: String {
        "\(row)-\(col)"
    }
}

struct FactStats: Equatable {
    var attempts: Int = 0
    var correct: Int = 0
    var lastCorrect: Bool? = nil

    mutating func record(isCorrect: Bool) {
        attempts += 1
        if isCorrect {
            correct += 1
        }
        lastCorrect = isCorrect
    }

    var accuracy: Double {
        guard attempts > 0 else { return 0 }
        return Double(correct) / Double(attempts)
    }

    var isMastered: Bool {
        attempts >= 3 && accuracy >= 0.8
    }
}
