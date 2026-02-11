//
//  ArithmeticReviewPanelView.swift
//  Multrix
//

import SwiftUI

struct ArithmeticReviewPanelView: View {
    let historyEntries: [ArithmeticHistoryEntry]
    @Binding var sortOption: HistorySortOption

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Text("Review")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Picker("Sort", selection: $sortOption) {
                    ForEach(HistorySortOption.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.menu)
            }

            if historyEntries.isEmpty {
                Text("No completed problems yet.")
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(historyEntries.prefix(20)) { item in
                        ArithmeticHistoryEntryRowView(entry: item)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }
}

private struct ArithmeticHistoryEntryRowView: View {
    let entry: ArithmeticHistoryEntry

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                Text(entry.lhsDisplay)
                    .font(.subheadline)
                Text(entry.operation.symbol)
                    .font(.subheadline)
                    .foregroundStyle(entry.operation.operatorColor)
                Text(entry.rhsDisplay)
                    .font(.subheadline)
            }

            Spacer()

            Text("= \(entry.answerDisplay)")
                .font(.subheadline)
                .monospacedDigit()
        }
        .padding(10)
        .background(Color.gray.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
