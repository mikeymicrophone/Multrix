//
//  ArithmeticModePickerView.swift
//  Multrix
//

import SwiftUI

struct ArithmeticModePickerView: View {
    @Binding var displayMode: ArithmeticDisplayMode

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mode")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker("Mode", selection: $displayMode) {
                ForEach(ArithmeticDisplayMode.allCases, id: \.self) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
