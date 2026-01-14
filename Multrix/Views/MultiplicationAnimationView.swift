//
//  MultiplicationAnimationView.swift
//  Multrix
//
//  Created by Mike Schwab on 1/13/26.
//

import SwiftUI

// MARK: - Animation Phase

enum AnimationPhase: Int, CaseIterable, Equatable {
    case ready = 0       // Copies appear at original positions
    case flyOut          // Cells fly to animation area
    case align           // Row and column align vertically
    case pair            // Values pair up with × symbols
    case multiply        // Show products sequentially
    case collapse        // Products collapse
    case sum             // Final sum appears
    case complete

    var description: String {
        switch self {
        case .ready: return "Ready"
        case .flyOut: return "Moving"
        case .align: return "Aligning"
        case .pair: return "Pairing"
        case .multiply: return "Multiplying"
        case .collapse: return "Combining"
        case .sum: return "Result"
        case .complete: return "Complete"
        }
    }
}

// MARK: - Animation Timing Configuration

struct AnimationTiming {
    // Each phase has duration and delay before it starts
    var flyOutDuration: Double = 0.5
    var flyOutDelay: Double = 0.2

    var alignDuration: Double = 0.4
    var alignDelay: Double = 0.2

    var pairDuration: Double = 0.4
    var pairDelay: Double = 0.2

    // Per-product timing (sequential)
    var productRevealDuration: Double = 0.3
    var productRevealDelay: Double = 0.5  // Delay between each product

    var collapseDuration: Double = 0.4
    var collapseDelay: Double = 0.4

    var sumDuration: Double = 0.3
    var sumDelay: Double = 0.2
}

// MARK: - Animated Cell Data

struct AnimatedCellData: Identifiable {
    let id: CellIdentifier
    let originalFrame: CGRect
    let value: Int
    let color: Color  // Blue for A, Purple for B
}

// MARK: - Animation Overlay View

struct MultiplicationAnimationOverlay: View {
    let cellPositions: [CellPositionData]
    let targetArea: CGRect  // Area to the right of Matrix B where animation happens
    let selectedRow: Int
    let selectedCol: Int
    let finalSum: Int
    let onComplete: () -> Void

    @State private var phase: AnimationPhase = .ready
    @State private var visibleProductCount: Int = 0  // How many products are visible (for sequential reveal)
    @State private var timing = AnimationTiming()

    // Separate the cells into row (from A) and column (from B)
    private var rowCells: [AnimatedCellData] {
        cellPositions
            .filter { $0.id.matrix == 0 && $0.id.row == selectedRow }
            .sorted { $0.id.col < $1.id.col }
            .map { AnimatedCellData(id: $0.id, originalFrame: $0.frame, value: $0.value, color: .blue) }
    }

    private var colCells: [AnimatedCellData] {
        cellPositions
            .filter { $0.id.matrix == 1 && $0.id.col == selectedCol }
            .sorted { $0.id.row < $1.id.row }
            .map { AnimatedCellData(id: $0.id, originalFrame: $0.frame, value: $0.value, color: .purple) }
    }

    private var products: [Int] {
        zip(rowCells, colCells).map { $0.value * $1.value }
    }

    private var count: Int { rowCells.count }

    // Animation area center
    private var animationCenter: CGPoint {
        CGPoint(x: targetArea.midX, y: targetArea.midY)
    }

    var body: some View {
        ZStack {
            // Row cells (from Matrix A - blue)
            ForEach(Array(rowCells.enumerated()), id: \.element.id) { index, cell in
                animatedRowCell(cell: cell, index: index)
            }

            // Column cells (from Matrix B - purple)
            ForEach(Array(colCells.enumerated()), id: \.element.id) { index, cell in
                animatedColCell(cell: cell, index: index)
            }

            // Multiplication symbols
            ForEach(0..<count, id: \.self) { index in
                multiplySymbol(index: index)
            }

            // Products
            ForEach(0..<count, id: \.self) { index in
                productView(index: index)
            }

            // Plus signs between products
            ForEach(0..<max(0, count - 1), id: \.self) { index in
                plusSign(index: index)
            }

            // Final sum
            sumView

            // Phase indicator and controls
            VStack {
                Spacer()
                HStack {
                    Text(phase.description)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.orange.opacity(0.8)))
                        .foregroundColor(.white)

                    Spacer()

                    Button("Reset") {
                        resetAnimation()
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.gray.opacity(0.3)))

                    Button("Close") {
                        onComplete()
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.blue))
                    .foregroundColor(.white)
                }
                .padding()
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    // MARK: - Row Cell (Matrix A)

    private func animatedRowCell(cell: AnimatedCellData, index: Int) -> some View {
        let position = rowCellPosition(cell: cell, index: index)
        let opacity = rowCellOpacity(index: index)

        return cellView(value: cell.value, color: cell.color)
            .position(position)
            .opacity(opacity)
    }

    private func rowCellPosition(cell: AnimatedCellData, index: Int) -> CGPoint {
        let verticalSpacing: CGFloat = 56
        let verticalOffset = CGFloat(index - count / 2) * verticalSpacing + (count.isMultiple(of: 2) ? verticalSpacing / 2 : 0)
        let finalPosition = CGPoint(x: animationCenter.x - 50, y: animationCenter.y + verticalOffset)

        switch phase {
        case .ready:
            // Start at original position in the matrix
            return CGPoint(x: cell.originalFrame.midX, y: cell.originalFrame.midY)
        case .flyOut, .align, .pair, .multiply, .collapse, .sum, .complete:
            // Each cell flies directly to its final vertical position
            // The pivot effect comes from the group going from horizontal to vertical
            return finalPosition
        }
    }

    private func rowCellOpacity(index: Int) -> Double {
        switch phase {
        case .ready, .flyOut, .align, .pair:
            return 1.0
        case .multiply:
            // Fade out as product is revealed
            return index < visibleProductCount ? 0.0 : 1.0
        case .collapse, .sum, .complete:
            return 0.0
        }
    }

    // MARK: - Column Cell (Matrix B)

    private func animatedColCell(cell: AnimatedCellData, index: Int) -> some View {
        let position = colCellPosition(cell: cell, index: index)
        let opacity = colCellOpacity(index: index)

        return cellView(value: cell.value, color: cell.color)
            .position(position)
            .opacity(opacity)
    }

    private func colCellPosition(cell: AnimatedCellData, index: Int) -> CGPoint {
        let verticalSpacing: CGFloat = 56
        let verticalOffset = CGFloat(index - count / 2) * verticalSpacing + (count.isMultiple(of: 2) ? verticalSpacing / 2 : 0)

        switch phase {
        case .ready:
            return CGPoint(x: cell.originalFrame.midX, y: cell.originalFrame.midY)
        case .flyOut, .align, .pair, .multiply, .collapse, .sum, .complete:
            // Align vertically on the right
            return CGPoint(x: animationCenter.x + 50, y: animationCenter.y + verticalOffset)
        }
    }

    private func colCellOpacity(index: Int) -> Double {
        switch phase {
        case .ready, .flyOut, .align, .pair:
            return 1.0
        case .multiply:
            // Fade out as product is revealed
            return index < visibleProductCount ? 0.0 : 1.0
        case .collapse, .sum, .complete:
            return 0.0
        }
    }

    // MARK: - Multiply Symbol

    private func multiplySymbol(index: Int) -> some View {
        let verticalSpacing: CGFloat = 56
        let verticalOffset = CGFloat(index - count / 2) * verticalSpacing + (count.isMultiple(of: 2) ? verticalSpacing / 2 : 0)

        let opacity: Double = {
            switch phase {
            case .pair:
                return 1.0
            case .multiply:
                // Hide as product is revealed
                return index < visibleProductCount ? 0.0 : 1.0
            default:
                return 0.0
            }
        }()

        return Text("×")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.gray)
            .position(x: animationCenter.x, y: animationCenter.y + verticalOffset)
            .opacity(opacity)
    }

    // MARK: - Product View

    private func productView(index: Int) -> some View {
        let verticalSpacing: CGFloat = 56
        let normalOffset = CGFloat(index - count / 2) * verticalSpacing + (count.isMultiple(of: 2) ? verticalSpacing / 2 : 0)

        let position: CGPoint = {
            switch phase {
            case .collapse, .sum, .complete:
                return CGPoint(x: animationCenter.x, y: animationCenter.y)
            default:
                return CGPoint(x: animationCenter.x, y: animationCenter.y + normalOffset)
            }
        }()

        let opacity: Double = {
            switch phase {
            case .multiply:
                // Show only if this product has been revealed
                return index < visibleProductCount ? 1.0 : 0.0
            case .collapse:
                return 1.0
            default:
                return 0.0
            }
        }()

        let scale: CGFloat = {
            switch phase {
            case .collapse, .sum, .complete:
                return 0.3
            default:
                return 1.0
            }
        }()

        return Text("\(products.indices.contains(index) ? products[index] : 0)")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(width: 56, height: 44)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.green.opacity(0.85)))
            .scaleEffect(scale)
            .position(position)
            .opacity(opacity)
    }

    // MARK: - Plus Sign

    private func plusSign(index: Int) -> some View {
        let verticalSpacing: CGFloat = 56
        let offset = CGFloat(index - count / 2) * verticalSpacing + verticalSpacing / 2 + (count.isMultiple(of: 2) ? verticalSpacing / 2 : 0)

        let opacity: Double = {
            switch phase {
            case .multiply:
                // Show plus sign after the product at this index is revealed
                return index < visibleProductCount - 1 ? 1.0 : 0.0
            case .collapse:
                return 1.0
            default:
                return 0.0
            }
        }()

        return Text("+")
            .font(.title3)
            .fontWeight(.bold)
            .foregroundColor(.green)
            .position(x: animationCenter.x, y: animationCenter.y + offset)
            .opacity(opacity)
    }

    // MARK: - Sum View

    private var sumView: some View {
        let opacity: Double = {
            switch phase {
            case .sum, .complete:
                return 1.0
            default:
                return 0.0
            }
        }()

        let scale: CGFloat = {
            switch phase {
            case .sum:
                return 1.3
            case .complete:
                return 1.0
            default:
                return 0.5
            }
        }()

        return Text("\(finalSum)")
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(width: 80, height: 60)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.green))
            .scaleEffect(scale)
            .position(animationCenter)
            .opacity(opacity)
    }

    // MARK: - Cell View Helper

    private func cellView(value: Int, color: Color) -> some View {
        Text("\(value)")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(color)
            .frame(width: 44, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.2))
                    .stroke(color, lineWidth: 2)
            )
    }

    // MARK: - Animation Control

    private func startAnimation() {
        var totalDelay: Double = timing.flyOutDelay

        // Phase 1: Fly out
        withAnimation(.easeInOut(duration: timing.flyOutDuration).delay(totalDelay)) {
            phase = .flyOut
        }
        totalDelay += timing.flyOutDuration + timing.alignDelay

        // Phase 2: Align (skipped since flyOut goes directly to aligned position)
        withAnimation(.easeInOut(duration: timing.alignDuration).delay(totalDelay)) {
            phase = .align
        }
        totalDelay += timing.alignDuration + timing.pairDelay

        // Phase 3: Pair
        withAnimation(.easeInOut(duration: timing.pairDuration).delay(totalDelay)) {
            phase = .pair
        }
        totalDelay += timing.pairDuration + timing.productRevealDelay

        // Phase 4: Multiply - reveal products sequentially
        withAnimation(.easeInOut(duration: 0.1).delay(totalDelay)) {
            phase = .multiply
        }

        // Reveal each product one at a time
        for i in 0..<count {
            let productDelay = totalDelay + Double(i) * timing.productRevealDelay
            withAnimation(.easeInOut(duration: timing.productRevealDuration).delay(productDelay)) {
                visibleProductCount = i + 1
            }
        }
        totalDelay += Double(count) * timing.productRevealDelay + timing.collapseDelay

        // Phase 5: Collapse
        withAnimation(.easeInOut(duration: timing.collapseDuration).delay(totalDelay)) {
            phase = .collapse
        }
        totalDelay += timing.collapseDuration + timing.sumDelay

        // Phase 6: Sum
        withAnimation(.easeInOut(duration: timing.sumDuration).delay(totalDelay)) {
            phase = .sum
        }
        totalDelay += timing.sumDuration + 0.3

        // Phase 7: Complete
        withAnimation(.easeInOut(duration: 0.2).delay(totalDelay)) {
            phase = .complete
        }
    }

    private func resetAnimation() {
        withAnimation(.easeInOut(duration: 0.2)) {
            phase = .ready
            visibleProductCount = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            startAnimation()
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.opacity(0.1)
        MultiplicationAnimationOverlay(
            cellPositions: [
                CellPositionData(id: CellIdentifier(matrix: 0, row: 0, col: 0), frame: CGRect(x: 50, y: 100, width: 50, height: 50), value: 2),
                CellPositionData(id: CellIdentifier(matrix: 0, row: 0, col: 1), frame: CGRect(x: 104, y: 100, width: 50, height: 50), value: 3),
                CellPositionData(id: CellIdentifier(matrix: 1, row: 0, col: 0), frame: CGRect(x: 200, y: 100, width: 50, height: 50), value: 4),
                CellPositionData(id: CellIdentifier(matrix: 1, row: 1, col: 0), frame: CGRect(x: 200, y: 154, width: 50, height: 50), value: 5),
            ],
            targetArea: CGRect(x: 300, y: 100, width: 200, height: 300),
            selectedRow: 0,
            selectedCol: 0,
            finalSum: 23,
            onComplete: {}
        )
    }
}
