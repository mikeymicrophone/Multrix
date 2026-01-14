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

#Preview {
    @Previewable @State var isPresented = true
    NumberInputView(isPresented: $isPresented) { number in
        print("Selected \(number)")
    }
}
