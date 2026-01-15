//
//  ResetButtonView.swift
//  Multrix
//

import SwiftUI

struct ResetButtonView: View {
    let onReset: () -> Void

    var body: some View {
        Button(action: onReset) {
            HStack {
                Image(systemName: "arrow.counterclockwise")
                Text("New Matrices")
            }
            .font(.subheadline)
            .foregroundColor(.blue)
        }
        .padding(.bottom)
    }
}

// MARK: - Previews

#Preview {
    ResetButtonView(onReset: {})
}
