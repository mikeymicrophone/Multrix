//
//  MatrixCellView.swift
//  Multrix
//
//  Created by Mike Schwab on 1/13/26.
//

import SwiftUI

struct MatrixCellView: View {
    let value: Int?
    let isEditable: Bool
    let onTap: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(isEditable ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                .stroke(isEditable ? Color.blue : Color.gray.opacity(0.3), lineWidth: isEditable ? 2 : 1)

            if let val = value {
                Text("\(val)")
                    .font(.title2)
                    .fontWeight(.medium)
            } else {
                Text("?")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
        }
        .frame(width: 50, height: 50)
        .onTapGesture {
            if isEditable {
                onTap()
            }
        }
    }
}

#Preview {
    HStack {
        MatrixCellView(value: 5, isEditable: false, onTap: {})
        MatrixCellView(value: nil, isEditable: true, onTap: {})
    }
}
