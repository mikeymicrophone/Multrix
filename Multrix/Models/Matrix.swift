//
//  Matrix.swift
//  Multrix
//
//  Created by Mike Schwab on 1/13/26.
//

import Foundation

struct Matrix: Identifiable {
    let id = UUID()
    var values: [[Int?]]
    var missingRow: Int
    var missingCol: Int
    let rows: Int
    let cols: Int

    init(rows: Int, cols: Int) {
        self.rows = rows
        self.cols = cols

        // Generate random matrix with one missing cell
        var grid: [[Int?]] = []
        for _ in 0..<rows {
            var row: [Int?] = []
            for _ in 0..<cols {
                row.append(Int.random(in: 0...9))
            }
            grid.append(row)
        }

        // Pick a random cell to be empty
        missingRow = Int.random(in: 0..<rows)
        missingCol = Int.random(in: 0..<cols)
        grid[missingRow][missingCol] = nil

        values = grid
    }

    var isComplete: Bool {
        values[missingRow][missingCol] != nil
    }
}
