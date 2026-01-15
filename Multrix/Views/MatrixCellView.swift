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
    let cellId: CellIdentifier?  // If set, reports position when highlighted
    let dimmed: Bool
    let onTap: () -> Void

    init(value: Int?, isHighlighted: Bool, cellId: CellIdentifier? = nil, dimmed: Bool = false, onTap: @escaping () -> Void) {
        self.value = value
        self.isHighlighted = isHighlighted
        self.cellId = cellId
        self.dimmed = dimmed
        self.onTap = onTap
    }

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
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundColor(isHighlighted ? .orange : .primary)
            } else {
                Text("?")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
        }
        .frame(width: 50, height: 50)
        .opacity(dimmed ? 0.3 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(
                        key: CellPositionPreferenceKey.self,
                        value: cellId != nil && isHighlighted ? [
                            CellPositionData(
                                id: cellId!,
                                frame: geo.frame(in: .named(MatrixCoordinateSpace.name)),
                                value: value ?? 0
                            )
                        ] : []
                    )
            }
        )
    }
}

#Preview {
    HStack {
        MatrixCellView(value: 5, isHighlighted: false, onTap: {})
        MatrixCellView(value: nil, isHighlighted: false, onTap: {})
        MatrixCellView(value: 7, isHighlighted: true, onTap: {})
    }
}
