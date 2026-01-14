//
//  MatrixCellView.swift
//  Multrix
//
//  Created by Mike Schwab on 1/13/26.
//

import SwiftUI

struct MatrixCellView: View {
    let value: Int?
    let isHighlighted: Bool
    let onTap: () -> Void

    private var isEmpty: Bool { value == nil }

    private var fillColor: Color {
        if isHighlighted {
            return Color.orange.opacity(0.3)
        } else if isEmpty {
            return Color.blue.opacity(0.2)
        } else {
            return Color.gray.opacity(0.1)
        }
    }

    private var strokeColor: Color {
        if isHighlighted {
            return Color.orange
        } else if isEmpty {
            return Color.blue
        } else {
            return Color.gray.opacity(0.3)
        }
    }

    private var strokeWidth: CGFloat {
        (isHighlighted || isEmpty) ? 2 : 1
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(fillColor)
                .stroke(strokeColor, lineWidth: strokeWidth)

            if let val = value {
                Text("\(val)")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(isHighlighted ? .orange : .primary)
            } else {
                Text("?")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
        }
        .frame(width: 50, height: 50)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    HStack {
        MatrixCellView(value: 5, isHighlighted: false, onTap: {})
        MatrixCellView(value: nil, isHighlighted: false, onTap: {})
        MatrixCellView(value: 7, isHighlighted: true, onTap: {})
    }
}
