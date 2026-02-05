//
//  RootTabView.swift
//  Multrix
//

import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            ArithmeticPracticeView(
                title: "Addition & Subtraction",
                operations: [.addition, .subtraction]
            )
            .tabItem {
                Label("Add/Sub", systemImage: "plusminus")
            }

            ArithmeticPracticeView(
                title: "Multiplication & Division",
                operations: [.multiplication, .division]
            )
            .tabItem {
                Label("Mul/Div", systemImage: "multiply")
            }

            ContentView()
                .tabItem {
                    Label("Matrix", systemImage: "square.grid.3x3")
                }
        }
    }
}

#Preview {
    RootTabView()
}
