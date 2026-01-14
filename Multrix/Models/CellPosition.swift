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

// Result matrix cell identification
struct ResultCellIdentifier: Hashable {
    let row: Int
    let col: Int
}

// Position data for a result cell
struct ResultCellPositionData: Equatable {
    let id: ResultCellIdentifier
    let frame: CGRect
}

// PreferenceKey to collect result cell positions
struct ResultCellPositionPreferenceKey: PreferenceKey {
    static var defaultValue: [ResultCellPositionData] = []

    static func reduce(value: inout [ResultCellPositionData], nextValue: () -> [ResultCellPositionData]) {
        value.append(contentsOf: nextValue())
    }
}
