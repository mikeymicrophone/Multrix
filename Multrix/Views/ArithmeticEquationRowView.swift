//
//  ArithmeticEquationRowView.swift
//  Multrix
//

import SwiftUI

struct ArithmeticEquationRowView: View {
    let problem: ArithmeticProblem
    let displayMode: ArithmeticDisplayMode
    let onEditLhs: () -> Void
    let onToggleOperation: () -> Void
    let onEditRhs: () -> Void
    let onRefresh: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 20) {
                editableOperandView(
                    text: problem.lhsDisplay(mode: displayMode),
                    editIconAlignment: .topLeading,
                    editIconXOffset: -14,
                    editAccessibilityLabel: "Edit first operand",
                    onEdit: onEditLhs
                )

                editableOperationView

                editableOperandView(
                    text: problem.rhsDisplay(mode: displayMode),
                    editIconAlignment: .topTrailing,
                    editIconXOffset: 14,
                    editAccessibilityLabel: "Edit second operand",
                    onEdit: onEditRhs
                )
            }
            .frame(maxWidth: .infinity)

            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
                    .font(.title3)
                    .padding(8)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(Circle())
            }
            .accessibilityLabel("New problem")
        }
    }

    @ViewBuilder
    private func editableOperandView(
        text: String,
        editIconAlignment: Alignment,
        editIconXOffset: CGFloat,
        editAccessibilityLabel: String,
        onEdit: @escaping () -> Void
    ) -> some View {
        Text(text)
            .font(equationFont)
            .fontWeight(.semibold)
            .minimumScaleFactor(0.45)
            .lineLimit(1)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
            .overlay(alignment: editIconAlignment) {
                smallEditButton(
                    icon: "pencil",
                    accessibilityLabel: editAccessibilityLabel,
                    action: onEdit
                )
                .offset(x: editIconXOffset, y: -22)
            }
    }

    private var editableOperationView: some View {
        Text(problem.operation.symbol)
            .font(equationFont)
            .fontWeight(.semibold)
            .foregroundStyle(problem.operation.operatorColor)
            .overlay(alignment: .top) {
                smallEditButton(
                    icon: "arrow.triangle.2.circlepath",
                    accessibilityLabel: "Toggle operation",
                    action: onToggleOperation
                )
                .offset(y: -26)
            }
    }

    @ViewBuilder
    private func smallEditButton(
        icon: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.caption)
                .padding(5)
                .background(Color.blue.opacity(0.12))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private var equationFont: Font {
        .system(size: 46, weight: .bold, design: .rounded)
    }
}
