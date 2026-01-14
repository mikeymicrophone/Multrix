//
//  DimensionPickerView.swift
//  Multrix
//
//  Created by Mike Schwab on 1/13/26.
//

import SwiftUI

struct DimensionPickerView: View {
    @Binding var rowsA: Int      // m - rows of Matrix A
    @Binding var shared: Int     // n - cols of A / rows of B
    @Binding var colsB: Int      // p - cols of Matrix B
    let onApply: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Matrix Dimensions")
                .font(.headline)

            // Visual representation
            HStack(spacing: 8) {
                Text("A")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                Text("[\(rowsA)×\(shared)]")
                    .font(.system(.body, design: .monospaced))

                Text("×")
                    .font(.title2)

                Text("B")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                Text("[\(shared)×\(colsB)]")
                    .font(.system(.body, design: .monospaced))

                Text("=")
                    .font(.title2)

                Text("[\(rowsA)×\(colsB)]")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.green)
            }

            Divider()

            // Pickers
            VStack(spacing: 12) {
                HStack {
                    Text("Rows of A (m)")
                        .frame(width: 120, alignment: .leading)
                    Picker("", selection: $rowsA) {
                        ForEach(1...6, id: \.self) { n in
                            Text("\(n)").tag(n)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                HStack {
                    Text("Shared (n)")
                        .frame(width: 120, alignment: .leading)
                    Picker("", selection: $shared) {
                        ForEach(1...6, id: \.self) { n in
                            Text("\(n)").tag(n)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                HStack {
                    Text("Cols of B (p)")
                        .frame(width: 120, alignment: .leading)
                    Picker("", selection: $colsB) {
                        ForEach(1...6, id: \.self) { n in
                            Text("\(n)").tag(n)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }

            Button(action: onApply) {
                Text("Apply & Generate New Matrices")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(radius: 4)
        )
    }
}

#Preview {
    @Previewable @State var rowsA = 4
    @Previewable @State var shared = 4
    @Previewable @State var colsB = 4
    DimensionPickerView(rowsA: $rowsA, shared: $shared, colsB: $colsB) {
        print("Apply tapped")
    }
}
