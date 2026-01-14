//
//  Matrix.swift
//  Multrix
//
//  Created by Mike Schwab on 1/13/26.
//

import Foundation

struct Matrix: Identifiable {
    let id = UUID()
    var values: [[Int?]]  // 4x4 grid, nil represents the empty cell
    var missingRow: Int
    var missingCol: Int

    init() {
        // Generate random 4x4 matrix with one missing cell
        var grid: [[Int?]] = []
        for _ in 0..<4 {
            var row: [Int?] = []
            for _ in 0..<4 {
                row.append(Int.random(in: 0...9))
            }
            grid.append(row)
        }

        // Pick a random cell to be empty
        missingRow = Int.random(in: 0..<4)
        missingCol = Int.random(in: 0..<4)
        grid[missingRow][missingCol] = nil

        values = grid
    }

    var isComplete: Bool {
        values[missingRow][missingCol] != nil
    }
}
