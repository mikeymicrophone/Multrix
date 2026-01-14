//
//  CellPosition.swift
//  Multrix
//
//  Created by Mike Schwab on 1/13/26.
//

import SwiftUI

// Identifies which matrix and cell
struct CellIdentifier: Hashable {
    let matrix: Int  // 0 = A, 1 = B
    let row: Int
    let col: Int
}

// Position data for a cell
struct CellPositionData: Equatable {
    let id: CellIdentifier
    let frame: CGRect
    let value: Int
}

// PreferenceKey to collect cell positions
struct CellPositionPreferenceKey: PreferenceKey {
    static var defaultValue: [CellPositionData] = []

    static func reduce(value: inout [CellPositionData], nextValue: () -> [CellPositionData]) {
        value.append(contentsOf: nextValue())
    }
}

// Coordinate space name
enum MatrixCoordinateSpace {
    static let name = "matrixSpace"
}
