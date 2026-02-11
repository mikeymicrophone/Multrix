//
//  ArithmeticOperation+Style.swift
//  Multrix
//

import SwiftUI

extension ArithmeticOperation {
    var operatorColor: Color {
        switch self {
        case .addition: return .green
        case .subtraction: return .red
        case .multiplication: return .blue
        case .division: return .orange
        }
    }
}
