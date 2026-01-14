//
//  ContentView.swift
//  Multrix
//
//  Created by Mike Schwab on 1/13/26.
//

import SwiftUI

// MARK: - Matrix Model

struct Matrix: Identifiable {
    let id = UUID()
    var values: [[Int?]]  // 4x4 grid, nil represents the empty cell
    var missingRow: Int
    var missingCol: Int

    init() {
        // Generate random 4x4 matrix with one missing cell
        var grid: [[Int?]] = []
        for _ in 0..<4 {
            var row: [Int?] = []
            for _ in 0..<4 {
                row.append(Int.random(in: 1...9))
            }
            grid.append(row)
        }

        // Pick a random cell to be empty
        missingRow = Int.random(in: 0..<4)
        missingCol = Int.random(in: 0..<4)
        grid[missingRow][missingCol] = nil

        values = grid
    }

    var isComplete: Bool {
        values[missingRow][missingCol] != nil
    }
}

// MARK: - Matrix Cell View

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

// MARK: - Matrix View

struct MatrixView: View {
    @Binding var matrix: Matrix
    let onCellTap: (Int, Int) -> Void

    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<4, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<4, id: \.self) { col in
                        MatrixCellView(
                            value: matrix.values[row][col],
                            isEditable: row == matrix.missingRow && col == matrix.missingCol
                        ) {
                            onCellTap(row, col)
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Result Matrix View

struct ResultMatrixView: View {
    let values: [[Int]]

    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<4, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<4, id: \.self) { col in
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.green.opacity(0.1))
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)

                            Text("\(values[row][col])")
                                .font(.system(size: 14))
                                .fontWeight(.medium)
                                .minimumScaleFactor(0.5)
                        }
                        .frame(width: 50, height: 50)
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.5), lineWidth: 2)
        )
    }
}

// MARK: - Number Input View

struct NumberInputView: View {
    @Binding var isPresented: Bool
    let onNumberSelected: (Int) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Enter a number")
                .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.fixed(60)), count: 3), spacing: 12) {
                ForEach(1...9, id: \.self) { number in
                    Button(action: {
                        onNumberSelected(number)
                        isPresented = false
                    }) {
                        Text("\(number)")
                            .font(.title)
                            .frame(width: 60, height: 60)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
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
}

// MARK: - Content View

struct ContentView: View {
    @State private var matrixA = Matrix()
    @State private var matrixB = Matrix()
    @State private var result: [[Int]]? = nil
    @State private var showingNumberInput = false
    @State private var editingMatrix: Int = 0  // 0 for A, 1 for B
    @State private var editingRow: Int = 0
    @State private var editingCol: Int = 0

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

                // Result
                if let result = result {
                    VStack(spacing: 8) {
                        Text("Result")
                            .font(.headline)
                        ResultMatrixView(values: result)
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
    }
}

#Preview {
    ContentView()
}
