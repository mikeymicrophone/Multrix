//
//  ContentView.swift
//  Multrix
//
//  Created by Mike Schwab on 1/13/26.
//

import SwiftUI

struct ContentView: View {
    @State private var matrixA = Matrix()
    @State private var matrixB = Matrix()
    @State private var result: [[Int]]? = nil
    @State private var showingNumberInput = false
    @State private var editingMatrix: Int = 0  // 0 for A, 1 for B
    @State private var editingRow: Int = 0
    @State private var editingCol: Int = 0
    @State private var selectedResultRow: Int? = nil
    @State private var selectedResultCol: Int? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Matrix Multiplication")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                Text("Tap the blue cell in each matrix to enter the missing number")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Matrix A
                VStack(spacing: 8) {
                    Text("Matrix A")
                        .font(.headline)
                    MatrixView(matrix: $matrixA) { row, col in
                        editingMatrix = 0
                        editingRow = row
                        editingCol = col
                        showingNumberInput = true
                    }
                }

                Text("×")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // Matrix B
                VStack(spacing: 8) {
                    Text("Matrix B")
                        .font(.headline)
                    MatrixView(matrix: $matrixB) { row, col in
                        editingMatrix = 1
                        editingRow = row
                        editingCol = col
                        showingNumberInput = true
                    }
                }

                // Calculate Button
                Button(action: calculateResult) {
                    HStack {
                        Image(systemName: "equal")
                        Text("Calculate Result")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(canCalculate ? Color.blue : Color.gray)
                    .cornerRadius(12)
                }
                .disabled(!canCalculate)
                .padding(.horizontal)

                if !canCalculate {
                    Text("Fill in the missing numbers to calculate")
                        .font(.caption)
                        .foregroundColor(.orange)
                }

                // Calculation Breakdown
                if let result = result,
                   let selectedRow = selectedResultRow,
                   let selectedCol = selectedResultCol {
                    CalculationBreakdownView(
                        matrixA: matrixA,
                        matrixB: matrixB,
                        resultRow: selectedRow,
                        resultCol: selectedCol,
                        resultValue: result[selectedRow][selectedCol]
                    )
                    .transition(.scale.combined(with: .opacity))
                }

                // Result
                if let result = result {
                    VStack(spacing: 8) {
                        Text("Result")
                            .font(.headline)
                        Text("Tap a cell to see how it was calculated")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ResultMatrixView(
                            values: result,
                            selectedRow: selectedResultRow,
                            selectedCol: selectedResultCol
                        ) { row, col in
                            if selectedResultRow == row && selectedResultCol == col {
                                // Deselect if tapping same cell
                                selectedResultRow = nil
                                selectedResultCol = nil
                            } else {
                                selectedResultRow = row
                                selectedResultCol = col
                            }
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                // Reset Button
                Button(action: reset) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("New Matrices")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
                .padding(.bottom)
            }
            .padding()
        }
        .overlay {
            if showingNumberInput {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showingNumberInput = false
                    }

                NumberInputView(isPresented: $showingNumberInput) { number in
                    if editingMatrix == 0 {
                        matrixA.values[editingRow][editingCol] = number
                    } else {
                        matrixB.values[editingRow][editingCol] = number
                    }
                }
            }
        }
        .animation(.easeInOut, value: result != nil)
        .animation(.easeInOut, value: showingNumberInput)
        .animation(.easeInOut, value: selectedResultRow)
        .animation(.easeInOut, value: selectedResultCol)
    }

    private var canCalculate: Bool {
        matrixA.isComplete && matrixB.isComplete
    }

    private func calculateResult() {
        // Matrix multiplication: C[i][j] = sum(A[i][k] * B[k][j]) for k in 0..<4
        var resultMatrix: [[Int]] = Array(repeating: Array(repeating: 0, count: 4), count: 4)

        for i in 0..<4 {
            for j in 0..<4 {
                var sum = 0
                for k in 0..<4 {
                    let a = matrixA.values[i][k] ?? 0
                    let b = matrixB.values[k][j] ?? 0
                    sum += a * b
                }
                resultMatrix[i][j] = sum
            }
        }

        result = resultMatrix
    }

    private func reset() {
        matrixA = Matrix()
        matrixB = Matrix()
        result = nil
        selectedResultRow = nil
        selectedResultCol = nil
    }
}

#Preview {
    ContentView()
}
