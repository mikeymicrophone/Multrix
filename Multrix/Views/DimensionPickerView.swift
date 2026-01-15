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

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Rows of A")
                    .frame(width: 100, alignment: .leading)
                Picker("", selection: $rowsA) {
                    ForEach(1...6, id: \.self) { n in
                        Text("\(n)").tag(n)
                    }
                }
                .pickerStyle(.segmented)
            }

            HStack {
                Text("Shared")
                    .frame(width: 100, alignment: .leading)
                Picker("", selection: $shared) {
                    ForEach(1...6, id: \.self) { n in
                        Text("\(n)").tag(n)
                    }
                }
                .pickerStyle(.segmented)
            }

            HStack {
                Text("Cols of B")
                    .frame(width: 100, alignment: .leading)
                Picker("", selection: $colsB) {
                    ForEach(1...6, id: \.self) { n in
                        Text("\(n)").tag(n)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }
}

#Preview {
    @Previewable @State var rowsA = 4
    @Previewable @State var shared = 4
    @Previewable @State var colsB = 4
    DimensionPickerView(rowsA: $rowsA, shared: $shared, colsB: $colsB)
}
