//
//  NumberInputView.swift
//  Multrix
//
//  Created by Mike Schwab on 1/13/26.
//

import SwiftUI

struct NumberInputView: View {
    @Binding var isPresented: Bool
    let onNumberSelected: (Int) -> Void

    @State private var tensMode: Bool = false
    @State private var tensDigit: Int? = nil

    private var displayText: String {
        if let tens = tensDigit {
            return "\(tens)_"
        } else if tensMode {
            return "_"
        }
        return ""
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Enter a number")
                .font(.headline)

            // Show display only when in tens mode
            if tensMode {
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
                }
            }

            // Bottom row: _0 button, 0, empty space
            HStack(spacing: 12) {
                // Tens place button
                Button(action: { tensMode = true }) {
                    Text("_0")
                        .font(.title2)
                        .fontWeight(.medium)
                        .frame(width: 60, height: 60)
                        .background(tensMode ? Color.gray : Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(tensMode)

                Button(action: { digitTapped(0) }) {
                    Text("0")
                        .font(.title)
                        .frame(width: 60, height: 60)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                // Placeholder for symmetry
                Color.clear
                    .frame(width: 60, height: 60)
            }

            Button("Cancel") {
                isPresented = false
            }
            .padding(.top, 8)
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 20)
    }

    private func digitTapped(_ digit: Int) {
        if let tens = tensDigit {
            // We have tens digit, this is the ones digit - complete and submit
            let number = tens * 10 + digit
            onNumberSelected(number)
            isPresented = false
        } else if tensMode {
            // In tens mode but no tens digit yet - this digit is the tens place
            tensDigit = digit
        } else {
            // Normal mode - single digit, submit immediately
            onNumberSelected(digit)
            isPresented = false
        }
    }
}

#Preview {
    @Previewable @State var isPresented = true
    NumberInputView(isPresented: $isPresented) { number in
        print("Selected \(number)")
    }
}
