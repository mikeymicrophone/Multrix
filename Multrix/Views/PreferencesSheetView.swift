//
//  PreferencesSheetView.swift
//  Multrix
//

import SwiftUI

struct PreferencesSheetView: View {
    @Binding var rowsA: Int
    @Binding var shared: Int
    @Binding var colsB: Int
    @Binding var complexity: NumberComplexity
    @Binding var animationSpeed: AnimationSpeed
    @Binding var additionMode: AdditionMode
    let onDone: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                dimensionsSection
                complexitySection
                animationSpeedSection
                additionStyleSection
            }
            .navigationTitle("Preferences")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: onDone)
                }
            }
        }
        .interactiveDismissDisabled()
    }

    // MARK: - Sections

    private var dimensionsSection: some View {
        Section {
            DimensionPickerView(
                rowsA: $rowsA,
                shared: $shared,
                colsB: $colsB
            )
        } header: {
            Text("Matrix Dimensions")
        } footer: {
            Text("A[\(rowsA)×\(shared)] × B[\(shared)×\(colsB)] = Result[\(rowsA)×\(colsB)]")
        }
    }

    private var complexitySection: some View {
        Section {
            Picker("Complexity", selection: $complexity) {
                ForEach(NumberComplexity.allCases, id: \.self) { level in
                    Text(level.title).tag(level)
                }
            }
            .pickerStyle(.segmented)

            Text(complexity.description)
                .font(.caption)
                .foregroundColor(.secondary)
        } header: {
            Text("Number Complexity")
        }
    }

    private var animationSpeedSection: some View {
        Section("Animation Speed") {
            Picker("Speed", selection: $animationSpeed) {
                ForEach(AnimationSpeed.allCases, id: \.self) { speed in
                    Text(speed.title).tag(speed)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var additionStyleSection: some View {
        Section("Addition Style") {
            Picker("Style", selection: $additionMode) {
                ForEach(AdditionMode.allCases, id: \.self) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

// MARK: - Previews

#Preview("Default Settings") {
    PreferencesSheetView(
        rowsA: .constant(4),
        shared: .constant(4),
        colsB: .constant(4),
        complexity: .constant(.moderate),
        animationSpeed: .constant(.normal),
        additionMode: .constant(.collapse),
        onDone: {}
    )
}

#Preview("Custom Settings") {
    PreferencesSheetView(
        rowsA: .constant(2),
        shared: .constant(3),
        colsB: .constant(2),
        complexity: .constant(.ultra),
        animationSpeed: .constant(.fastest),
        additionMode: .constant(.longForm),
        onDone: {}
    )
}

#Preview("Large Dimensions") {
    PreferencesSheetView(
        rowsA: .constant(6),
        shared: .constant(6),
        colsB: .constant(6),
        complexity: .constant(.significant),
        animationSpeed: .constant(.fast),
        additionMode: .constant(.collapse),
        onDone: {}
    )
}
