//
//  Matrix.swift
//  Multrix
//
//  Created by Mike Schwab on 1/13/26.
//

import Foundation

enum NumberComplexity: Int, CaseIterable, Equatable {
    case basic       // Most numbers < 5
    case moderate    // All numbers < 10
    case significant // ~80% are 0-9, ~18% are 10-20, ~2% are 20-99
    case ultra       // All numbers can be 0-99

    var title: String {
        switch self {
        case .basic: return "Basic"
        case .moderate: return "Moderate"
        case .significant: return "Significant"
        case .ultra: return "Ultra"
        }
    }

    var description: String {
        switch self {
        case .basic: return "Most numbers under 5"
        case .moderate: return "Numbers 0-9"
        case .significant: return "Some 2-digit numbers"
        case .ultra: return "Numbers 0-99"
        }
    }

    func randomValue() -> Int {
        switch self {
        case .basic:
            // 80% chance of 0-4, 20% chance of 5-9
            let roll = Int.random(in: 1...100)
            if roll <= 80 {
                return Int.random(in: 0...4)
            } else {
                return Int.random(in: 5...9)
            }
        case .moderate:
            return Int.random(in: 0...9)
        case .significant:
            // 80% are 0-9, 18% are 10-20, 2% are 20-99
            let roll = Int.random(in: 1...100)
            if roll <= 80 {
                return Int.random(in: 0...9)
            } else if roll <= 98 {
                return Int.random(in: 10...20)
            } else {
                return Int.random(in: 21...99)
            }
        case .ultra:
            return Int.random(in: 0...99)
        }
    }
}

struct Matrix: Identifiable {
    let id = UUID()
    var values: [[Int?]]
    let rows: Int
    let cols: Int

    init(rows: Int, cols: Int, complexity: NumberComplexity = .moderate) {
        self.rows = rows
        self.cols = cols

        // Generate random matrix with one missing cell
        var grid: [[Int?]] = []
        for _ in 0..<rows {
            var row: [Int?] = []
            for _ in 0..<cols {
                row.append(complexity.randomValue())
            }
            grid.append(row)
        }

        // Pick a random cell to be empty
        let missingRow = Int.random(in: 0..<rows)
        let missingCol = Int.random(in: 0..<cols)
        grid[missingRow][missingCol] = nil

        values = grid
    }

    var isComplete: Bool {
        values.allSatisfy { row in
            row.allSatisfy { $0 != nil }
        }
    }
}
