//
//  NumberInputView.swift
//  Multrix
//
//  Created by Mike Schwab on 1/13/26.
//

import SwiftUI

struct NumberInputView: View {
    @Binding var isPresented: Bool
    let showsDecimalToggle: Bool
    let onNumberSelected: (Double) -> Void

    @State private var tensMode: Bool = false
    @State private var firstDigit: Int? = nil
    @State private var decimalMode: Bool = false

    init(
        isPresented: Binding<Bool>,
        showsDecimalToggle: Bool = false,
        onNumberSelected: @escaping (Double) -> Void
    ) {
        _isPresented = isPresented
        self.showsDecimalToggle = showsDecimalToggle
        self.onNumberSelected = onNumberSelected
    }

    private var displayText: String {
        if let firstDigit {
            return decimalMode ? "\(firstDigit)._" : "\(firstDigit)_"
        }
        if decimalMode {
            return "_._"
        }
        if tensMode {
            return "_"
        }
        return ""
    }

    private var showsDisplay: Bool {
        tensMode || decimalMode || firstDigit != nil
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Enter a number")
                .font(.headline)

            if showsDisplay {
                Text(displayText)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .frame(width: 100, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.opacity(0.1))
                            .stroke(Color.blue, lineWidth: 2)
                    )
            }

            // Number grid (1-9)
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(60)), count: 3), spacing: 12) {
                ForEach(1...9, id: \.self) { digit in
                    Button(action: { digitTapped(digit) }) {
                        Text("\(digit)")
                            .font(.title)
                            .frame(width: 60, height: 60)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .accessibilityIdentifier("numberInput.digit.\(digit)")
                }
            }

            // Bottom row: _0 button, 0, decimal toggle
            HStack(spacing: 12) {
                Button(action: { tensMode = true }) {
                    Text("_0")
                        .font(.title2)
                        .fontWeight(.medium)
                        .frame(width: 60, height: 60)
                        .background(tensMode ? Color.gray : Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .accessibilityIdentifier("numberInput.tens")
                .disabled(tensMode)

                Button(action: { digitTapped(0) }) {
                    Text("0")
                        .font(.title)
                        .frame(width: 60, height: 60)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .accessibilityIdentifier("numberInput.digit.0")

                if showsDecimalToggle {
                    Button(action: toggleDecimalMode) {
                        Text(".")
                            .font(.title)
                            .fontWeight(.medium)
                            .frame(width: 60, height: 60)
                            .background(decimalMode ? Color.yellow : Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .accessibilityIdentifier("numberInput.decimal")
                } else {
                    Color.clear
                        .frame(width: 60, height: 60)
                }
            }

            Button("Cancel") {
                isPresented = false
            }
            .accessibilityIdentifier("numberInput.cancel")
            .padding(.top, 8)
        }
        .accessibilityIdentifier("numberInput.container")
        .padding(20)
        .frame(width: 260)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 20)
    }

    private func digitTapped(_ digit: Int) {
        if let firstDigit {
            let value: Double
            if decimalMode {
                value = Double(firstDigit) + Double(digit) / 10.0
            } else {
                value = Double(firstDigit * 10 + digit)
            }
            onNumberSelected(value)
            isPresented = false
        } else if tensMode || decimalMode {
            firstDigit = digit
        } else {
            onNumberSelected(Double(digit))
            isPresented = false
        }
    }

    private func toggleDecimalMode() {
        guard showsDecimalToggle else { return }
        decimalMode.toggle()
    }
}

#Preview {
    @Previewable @State var isPresented = true
    NumberInputView(isPresented: $isPresented) { number in
        print("Selected \(number)")
    }
}
