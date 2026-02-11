//
//  RootTabView.swift
//  Multrix
//

import SwiftUI
import SwiftData

struct RootTabView: View {
    var body: some View {
        TabView {
            ArithmeticPracticeView(
                title: "Addition & Subtraction",
                operations: [.addition, .subtraction],
                historyGroup: "addSub"
            )
            .tabItem {
                Label("Add/Sub", systemImage: "plusminus")
            }

            ArithmeticPracticeView(
                title: "Multiplication & Division",
                operations: [.multiplication, .division],
                historyGroup: "mulDiv"
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
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: ArithmeticHistoryEntry.self, configurations: configuration)
    return RootTabView()
        .modelContainer(container)
}
