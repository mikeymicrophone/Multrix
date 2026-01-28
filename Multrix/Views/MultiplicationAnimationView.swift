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
    case flyToResult     // Sum flies to result cell
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
        case .flyToResult: return "Placing"
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

    var collapseDuration: Double = 0.3
    var collapseDelay: Double = 0.3
    var collapseStepDelay: Double = 0.4  // Delay between each product collapsing

    var sumDuration: Double = 0.3
    var sumDelay: Double = 0.2
    var flyToResultDuration: Double = 0.35
    var flyToResultDelay: Double = 0.2

    func scaled(for speed: AnimationSpeed) -> AnimationTiming {
        var timing = self
        timing.flyOutDuration *= speed.flyOutFactor
        timing.flyOutDelay *= speed.flyOutDelayFactor
        timing.alignDuration *= speed.alignFactor
        timing.alignDelay *= speed.alignDelayFactor
        timing.pairDuration *= speed.pairFactor
        timing.pairDelay *= speed.pairDelayFactor
        timing.productRevealDuration *= speed.productFactor
        timing.productRevealDelay *= speed.productDelayFactor
        timing.collapseDuration *= speed.collapseFactor
        timing.collapseDelay *= speed.collapseDelayFactor
        timing.collapseStepDelay *= speed.collapseStepDelayFactor
        timing.sumDuration *= speed.sumFactor
        timing.sumDelay *= speed.sumDelayFactor
        timing.flyToResultDuration *= speed.flyToResultFactor
        timing.flyToResultDelay *= speed.flyToResultDelayFactor
        return timing
    }
}

enum AdditionMode: Int, CaseIterable, Equatable {
    case collapse   // Products slide together into sum
    case longForm   // Traditional long addition with digits appearing right to left

    var title: String {
        switch self {
        case .collapse: return "Collapse"
        case .longForm: return "Long Addition"
        }
    }
}

enum AnimationSpeed: Int, CaseIterable, Equatable {
    case slow
    case normal
    case fast
    case fastest

    var title: String {
        switch self {
        case .slow: return "Slow"
        case .normal: return "Normal"
        case .fast: return "Fast"
        case .fastest: return "Turbo"
        }
    }

    var flyOutFactor: Double { phaseFactor }
    var flyOutDelayFactor: Double { delayFactor }
    var alignFactor: Double { phaseFactor }
    var alignDelayFactor: Double { delayFactor }
    var pairFactor: Double { phaseFactor }
    var pairDelayFactor: Double { delayFactor }
    var productFactor: Double { productPhaseFactor }
    var productDelayFactor: Double { productDelayPhaseFactor }
    var collapseFactor: Double { phaseFactor }
    var collapseDelayFactor: Double { delayFactor }
    var collapseStepDelayFactor: Double { collapseDelayPhaseFactor }
    var sumFactor: Double { sumPhaseFactor }
    var sumDelayFactor: Double { delayFactor }
    var flyToResultFactor: Double { flyPhaseFactor }
    var flyToResultDelayFactor: Double { delayFactor }

    private var phaseFactor: Double {
        switch self {
        case .slow: return 1.4
        case .normal: return 1.0
        case .fast: return 0.8
        case .fastest: return 0.3
        }
    }

    private var delayFactor: Double {
        switch self {
        case .slow: return 1.3
        case .normal: return 1.0
        case .fast: return 0.7
        case .fastest: return 0.15
        }
    }

    private var productPhaseFactor: Double {
        switch self {
        case .slow: return 1.5
        case .normal: return 1.0
        case .fast: return 0.7
        case .fastest: return 0.2
        }
    }

    private var productDelayPhaseFactor: Double {
        switch self {
        case .slow: return 1.4
        case .normal: return 1.0
        case .fast: return 0.6
        case .fastest: return 0.1
        }
    }

    private var collapseDelayPhaseFactor: Double {
        switch self {
        case .slow: return 1.4
        case .normal: return 1.0
        case .fast: return 0.7
        case .fastest: return 0.15
        }
    }

    private var sumPhaseFactor: Double {
        switch self {
        case .slow: return 1.3
        case .normal: return 1.0
        case .fast: return 0.75
        case .fastest: return 0.25
        }
    }

    private var flyPhaseFactor: Double {
        switch self {
        case .slow: return 1.2
        case .normal: return 1.0
        case .fast: return 0.8
        case .fastest: return 0.3
        }
    }
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
    let resultCellFrame: CGRect?
    let speed: AnimationSpeed
    let additionMode: AdditionMode
    @Binding var isPaused: Bool
    let onResultPlaced: ((CGRect, Int) -> Void)?
    let onAnimationFinished: (() -> Void)?

    @State private var phase: AnimationPhase = .ready
    @State private var visibleProductCount: Int = 0  // How many products are visible (for sequential reveal)
    @State private var collapsedCount: Int = 0  // How many products have collapsed into running sum
    @State private var visibleDigitCount: Int = 0  // For long form mode: digits revealed from right
    @State private var visibleCarryCount: Int = 0  // For long form mode: carries revealed
    @State private var timing = AnimationTiming()
    @State private var animationTask: Task<Void, Never>? = nil

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

    // Running sums: runningSums[i] = sum of products[0...i]
    private var runningSums: [Int] {
        var sums: [Int] = []
        var total = 0
        for product in products {
            total += product
            sums.append(total)
        }
        return sums
    }

    private var count: Int { rowCells.count }

    // Animation area center
    private var animationCenter: CGPoint {
        CGPoint(x: targetArea.midX, y: targetArea.midY)
    }

    private var resultCellCenter: CGPoint {
        if let frame = resultCellFrame {
            return CGPoint(x: frame.midX, y: frame.midY)
        }
        return animationCenter
    }

    var body: some View {
        ZStack {
            // Animated elements - allow touches to pass through
            Group {
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

                // Equals signs (long form mode only)
                if additionMode == .longForm {
                    ForEach(0..<count, id: \.self) { index in
                        equalsSign(index: index)
                    }
                }

                // Plus signs between products (collapse mode only)
                if additionMode == .collapse {
                    ForEach(0..<max(0, count - 1), id: \.self) { index in
                        plusSign(index: index)
                    }
                }

                // Long form addition elements
                if additionMode == .longForm {
                    longFormAdditionView
                }

                // Final sum
                sumView
            }
            .allowsHitTesting(false)
        }
        .onAppear {
            animationTask?.cancel()
            animationTask = Task { @MainActor in
                await runAnimation()
            }
        }
        .onDisappear {
            animationTask?.cancel()
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
        case .flyOut, .align, .pair, .multiply, .collapse, .sum, .flyToResult, .complete:
            // Each cell flies directly to its final vertical position
            // The pivot effect comes from the group going from horizontal to vertical
            return finalPosition
        }
    }

    private func rowCellOpacity(index: Int) -> Double {
        // Long form mode: factors stay visible throughout (until flyToResult)
        if additionMode == .longForm {
            switch phase {
            case .ready, .flyOut, .align, .pair, .multiply, .collapse, .sum, .complete:
                return 1.0  // Always visible in long form
            case .flyToResult:
                return 0.0
            }
        }
        // Collapse mode
        switch phase {
        case .ready, .flyOut, .align, .pair:
            return 1.0
        case .multiply:
            return index < visibleProductCount ? 0.0 : 1.0
        case .collapse, .sum, .flyToResult, .complete:
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
        case .flyOut, .align, .pair, .multiply, .collapse, .sum, .flyToResult, .complete:
            // Align vertically on the right
            return CGPoint(x: animationCenter.x + 50, y: animationCenter.y + verticalOffset)
        }
    }

    private func colCellOpacity(index: Int) -> Double {
        // Long form mode: factors stay visible throughout (until flyToResult)
        if additionMode == .longForm {
            switch phase {
            case .ready, .flyOut, .align, .pair, .multiply, .collapse, .sum, .complete:
                return 1.0  // Always visible in long form
            case .flyToResult:
                return 0.0
            }
        }
        // Collapse mode
        switch phase {
        case .ready, .flyOut, .align, .pair:
            return 1.0
        case .multiply:
            return index < visibleProductCount ? 0.0 : 1.0
        case .collapse, .sum, .flyToResult, .complete:
            return 0.0
        }
    }

    // MARK: - Multiply Symbol

    private func multiplySymbol(index: Int) -> some View {
        let verticalSpacing: CGFloat = 56
        let verticalOffset = CGFloat(index - count / 2) * verticalSpacing + (count.isMultiple(of: 2) ? verticalSpacing / 2 : 0)

        let opacity: Double = {
            // Long form mode: multiply symbol stays visible
            if additionMode == .longForm {
                switch phase {
                case .pair, .multiply, .collapse, .sum, .complete:
                    return 1.0
                case .flyToResult:
                    return 0.0
                default:
                    return 0.0
                }
            }
            // Collapse mode
            switch phase {
            case .pair:
                return 1.0
            case .multiply:
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
        let firstProductOffset = CGFloat(0 - count / 2) * verticalSpacing + (count.isMultiple(of: 2) ? verticalSpacing / 2 : 0)

        // Long form mode positions products further right to show full equation
        let longFormProductX = animationCenter.x + 130

        let position: CGPoint = {
            // Long form mode: products stay in place, further right
            if additionMode == .longForm {
                switch phase {
                case .flyToResult:
                    return resultCellCenter
                default:
                    return CGPoint(x: longFormProductX, y: animationCenter.y + normalOffset)
                }
            }
            // Collapse mode: products collapse together
            switch phase {
            case .collapse:
                if index == 0 {
                    return CGPoint(x: animationCenter.x, y: animationCenter.y + firstProductOffset)
                } else if index <= collapsedCount {
                    return CGPoint(x: animationCenter.x, y: animationCenter.y + firstProductOffset)
                } else {
                    return CGPoint(x: animationCenter.x, y: animationCenter.y + normalOffset)
                }
            case .sum, .complete:
                return CGPoint(x: animationCenter.x, y: animationCenter.y)
            case .flyToResult:
                return resultCellCenter
            default:
                return CGPoint(x: animationCenter.x, y: animationCenter.y + normalOffset)
            }
        }()

        // Determine what value to display
        let displayValue: Int = {
            // Long form mode: always show the actual product
            if additionMode == .longForm {
                return products.indices.contains(index) ? products[index] : 0
            }
            // Collapse mode: first product shows running sum
            if index == 0 && phase == .collapse && collapsedCount > 0 {
                return runningSums.indices.contains(collapsedCount) ? runningSums[collapsedCount] : products.first ?? 0
            } else {
                return products.indices.contains(index) ? products[index] : 0
            }
        }()

        let opacity: Double = {
            // Long form mode: products stay visible until flyToResult
            if additionMode == .longForm {
                switch phase {
                case .multiply:
                    return index < visibleProductCount ? 1.0 : 0.0
                case .collapse, .sum, .complete:
                    return 1.0
                case .flyToResult:
                    return 0.0
                default:
                    return 0.0
                }
            }
            // Collapse mode
            switch phase {
            case .multiply:
                return index < visibleProductCount ? 1.0 : 0.0
            case .collapse:
                if index == 0 {
                    return 1.0
                } else if index <= collapsedCount {
                    return 0.0
                } else {
                    return 1.0
                }
            case .sum, .complete, .flyToResult:
                return 0.0
            default:
                return 0.0
            }
        }()

        return Text("\(displayValue)")
            .font(.title3)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(width: 70, height: 44)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.green.opacity(0.85)))
            .position(position)
            .opacity(opacity)
    }

    // MARK: - Equals Sign (Long Form Mode)

    private func equalsSign(index: Int) -> some View {
        let verticalSpacing: CGFloat = 56
        let verticalOffset = CGFloat(index - count / 2) * verticalSpacing + (count.isMultiple(of: 2) ? verticalSpacing / 2 : 0)

        // Position between column cell (at +50) and product (at +130)
        let xPosition = animationCenter.x + 90

        let opacity: Double = {
            switch phase {
            case .multiply:
                // Show equals sign when the product at this index is revealed
                return index < visibleProductCount ? 1.0 : 0.0
            case .collapse, .sum, .complete:
                return 1.0
            case .flyToResult:
                return 0.0
            default:
                return 0.0
            }
        }()

        return Text("=")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.gray)
            .position(x: xPosition, y: animationCenter.y + verticalOffset)
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
                // Hide plus signs as products collapse
                // Plus sign at index i is between products i and i+1
                // Hide when product i+1 has collapsed (index < collapsedCount)
                return index < collapsedCount ? 0.0 : 1.0
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
        let verticalSpacing: CGFloat = 56
        let firstProductOffset = CGFloat(0 - count / 2) * verticalSpacing + (count.isMultiple(of: 2) ? verticalSpacing / 2 : 0)
        let lastProductOffset = CGFloat(count - 1 - count / 2) * verticalSpacing + (count.isMultiple(of: 2) ? verticalSpacing / 2 : 0)
        let firstProductPosition = CGPoint(x: animationCenter.x, y: animationCenter.y + firstProductOffset)
        let longFormSumPosition = CGPoint(x: animationCenter.x + 130, y: animationCenter.y + lastProductOffset + 60)

        let position: CGPoint = {
            if additionMode == .longForm {
                switch phase {
                case .flyToResult:
                    return resultCellCenter
                default:
                    return longFormSumPosition
                }
            }
            switch phase {
            case .sum:
                return firstProductPosition
            case .complete:
                return animationCenter
            case .flyToResult:
                return resultCellCenter
            default:
                return firstProductPosition
            }
        }()

        let opacity: Double = {
            if additionMode == .longForm {
                // In long form, only show during flyToResult
                return phase == .flyToResult ? 1.0 : 0.0
            }
            switch phase {
            case .sum, .complete, .flyToResult:
                return 1.0
            default:
                return 0.0
            }
        }()

        let scale: CGFloat = {
            if additionMode == .longForm {
                return phase == .flyToResult ? 0.65 : 0.8
            }
            switch phase {
            case .sum:
                return 1.3
            case .complete:
                return 1.0
            case .flyToResult:
                return 0.65
            default:
                return 0.8
            }
        }()

        return Text("\(finalSum)")
            .font(.title)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(width: 90, height: 50)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.green))
            .scaleEffect(scale)
            .position(position)
            .opacity(opacity)
    }

    // MARK: - Long Form Addition View

    // Calculate carries for long addition
    private var carries: [Int] {
        var result: [Int] = []
        var carry = 0

        // Find max digit count among products
        let maxDigits = products.map { digitsOf($0).count }.max() ?? 1

        for digitPos in 0..<maxDigits {
            var columnSum = carry
            for product in products {
                let digits = digitsOf(product)
                if digitPos < digits.count {
                    columnSum += digits[digitPos]
                }
            }
            carry = columnSum / 10
            result.append(carry)
        }

        // Add final carry if exists
        if carry > 0 {
            result.append(0)  // No carry beyond the final digit
        }

        return result  // carries[i] is the carry from position i to position i+1
    }

    private var longFormAdditionView: some View {
        let verticalSpacing: CGFloat = 56
        let firstProductOffset = CGFloat(0 - count / 2) * verticalSpacing + (count.isMultiple(of: 2) ? verticalSpacing / 2 : 0)
        let lastProductOffset = CGFloat(count - 1 - count / 2) * verticalSpacing + (count.isMultiple(of: 2) ? verticalSpacing / 2 : 0)
        let lineY = animationCenter.y + lastProductOffset + 30
        let sumY = lineY + 30
        let carryY = animationCenter.y + firstProductOffset - 25  // Above the first product

        // Products are at x + 130, so line and sum should be centered there
        let productCenterX = animationCenter.x + 130

        let showLine = phase == .collapse || phase == .sum || phase == .complete
        let showPlusSign = phase == .collapse || phase == .sum || phase == .complete

        // Calculate the digits of the sum
        let sumDigits = digitsOf(finalSum)
        let digitCount = sumDigits.count
        let digitSpacing: CGFloat = 16

        // Find the widest product to size the line appropriately
        let maxProductDigits = products.map { digitsOf($0).count }.max() ?? 1
        let lineWidth = max(80, CGFloat(max(maxProductDigits, digitCount)) * digitSpacing + 40)

        return Group {
            // Plus sign to the left of the products
            Text("+")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.orange)
                .position(x: productCenterX - lineWidth / 2 - 15, y: lineY - 15)
                .opacity(showPlusSign ? 1.0 : 0.0)

            // Horizontal line below products
            Rectangle()
                .fill(Color.primary)
                .frame(width: lineWidth, height: 2)
                .position(x: productCenterX, y: lineY)
                .opacity(showLine ? 1.0 : 0.0)

            // Carry digits above the products (appear during sum phase)
            ForEach(0..<carries.count, id: \.self) { carryIndex in
                let carryValue = carries[carryIndex]
                if carryValue > 0 {
                    // Position carry above the next column to the left
                    // carryIndex 0 means carry from ones to tens, so position above tens column
                    let xOffset = -CGFloat(carryIndex + 1) * digitSpacing + CGFloat(digitCount - 1) * digitSpacing / 2
                    let isVisible = carryIndex < visibleCarryCount

                    Text("\(carryValue)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                        .position(x: productCenterX + xOffset, y: carryY)
                        .opacity(isVisible && (phase == .sum || phase == .complete) ? 1.0 : 0.0)
                        .scaleEffect(isVisible ? 1.0 : 0.3)
                }
            }

            // Sum digits appearing from right to left
            ForEach(0..<digitCount, id: \.self) { digitIndex in
                let digit = sumDigits[digitCount - 1 - digitIndex]  // Reverse order for display
                // Right-align: rightmost digit at productCenterX + offset, moving left
                let xOffset = -CGFloat(digitCount - 1 - digitIndex) * digitSpacing + CGFloat(digitCount - 1) * digitSpacing / 2
                let isVisible = (digitCount - 1 - digitIndex) < visibleDigitCount

                Text("\(digit)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                    .position(x: productCenterX + xOffset, y: sumY)
                    .opacity(isVisible && (phase == .sum || phase == .complete) ? 1.0 : 0.0)
                    .scaleEffect(isVisible ? 1.0 : 0.5)
            }
        }
    }

    private func digitsOf(_ number: Int) -> [Int] {
        if number == 0 { return [0] }
        var n = abs(number)
        var digits: [Int] = []
        while n > 0 {
            digits.append(n % 10)
            n /= 10
        }
        return digits  // Returns digits in reverse order (ones place first)
    }

    // MARK: - Cell View Helper

    private func cellView(value: Int, color: Color) -> some View {
        Text("\(value)")
            .font(.title2)
            .fontWeight(.bold)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .foregroundColor(color)
            .frame(width: 44, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.2))
                    .stroke(color, lineWidth: 2)
            )
    }

    // MARK: - Animation Control

    private func runAnimation() async {
        guard count > 0 else { return }
        let adjustedTiming = timing.scaled(for: speed)
        var totalDelay: Double = adjustedTiming.flyOutDelay

        // Phase 1: Fly out
        await pauseAwareSleep(seconds: totalDelay)
        withAnimation(.easeInOut(duration: adjustedTiming.flyOutDuration)) {
            phase = .flyOut
        }
        await pauseAwareSleep(seconds: adjustedTiming.flyOutDuration + adjustedTiming.alignDelay)

        // Phase 2: Align (skipped since flyOut goes directly to aligned position)
        withAnimation(.easeInOut(duration: adjustedTiming.alignDuration)) {
            phase = .align
        }
        await pauseAwareSleep(seconds: adjustedTiming.alignDuration + adjustedTiming.pairDelay)

        // Phase 3: Pair
        withAnimation(.easeInOut(duration: adjustedTiming.pairDuration)) {
            phase = .pair
        }
        await pauseAwareSleep(seconds: adjustedTiming.pairDuration + adjustedTiming.productRevealDelay)

        // Phase 4: Multiply - reveal products sequentially
        let quickTransition = speed == .fastest ? 0.03 : 0.1
        withAnimation(.easeInOut(duration: quickTransition)) {
            phase = .multiply
        }

        // Reveal each product one at a time
        for i in 0..<count {
            await pauseAwareSleep(seconds: adjustedTiming.productRevealDelay)
            withAnimation(.easeInOut(duration: adjustedTiming.productRevealDuration)) {
                visibleProductCount = i + 1
            }
        }
        await pauseAwareSleep(seconds: adjustedTiming.productRevealDuration)
        await pauseAwareSleep(seconds: adjustedTiming.collapseDelay)

        // Phase 5: Collapse - different behavior based on mode
        withAnimation(.easeInOut(duration: quickTransition)) {
            phase = .collapse
        }

        if additionMode == .longForm {
            // Long form: just show line and plus sign, no collapse animation
            await pauseAwareSleep(seconds: adjustedTiming.collapseDelay)
        } else {
            // Collapse mode: products move up and merge into running sum
            if count > 1 {
                for i in 1..<count {
                    await pauseAwareSleep(seconds: adjustedTiming.collapseStepDelay)
                    withAnimation(.easeInOut(duration: adjustedTiming.collapseDuration)) {
                        collapsedCount = i
                    }
                }
                await pauseAwareSleep(seconds: adjustedTiming.collapseDuration)
            }
        }
        await pauseAwareSleep(seconds: adjustedTiming.sumDelay)

        // Phase 6: Sum
        withAnimation(.easeInOut(duration: adjustedTiming.sumDuration)) {
            phase = .sum
        }

        if additionMode == .longForm {
            // Long form: reveal digits one at a time from right to left, with carries
            let digitCount = digitsOf(finalSum).count
            let carryList = carries
            let digitDelay = speed == .fastest ? 0.08 : (speed == .fast ? 0.15 : 0.25)
            for i in 0..<digitCount {
                await pauseAwareSleep(seconds: digitDelay)
                withAnimation(.easeInOut(duration: 0.15)) {
                    visibleDigitCount = i + 1
                    // Show carry if there is one at this position (carry from position i)
                    if i < carryList.count && carryList[i] > 0 {
                        visibleCarryCount = i + 1
                    }
                }
            }
            await pauseAwareSleep(seconds: 0.2)
        } else {
            let sumPause = speed == .fastest ? 0.05 : 0.3
            await pauseAwareSleep(seconds: adjustedTiming.sumDuration + sumPause)
        }

        // Phase 7: Complete
        let completeDuration = speed == .fastest ? 0.05 : 0.2
        withAnimation(.easeInOut(duration: completeDuration)) {
            phase = .complete
        }
        await pauseAwareSleep(seconds: completeDuration + adjustedTiming.flyToResultDelay)

        // Phase 8: Fly to result cell
        withAnimation(.easeInOut(duration: adjustedTiming.flyToResultDuration)) {
            phase = .flyToResult
        }
        await pauseAwareSleep(seconds: adjustedTiming.flyToResultDuration)
        if let frame = resultCellFrame {
            onResultPlaced?(frame, finalSum)
        }
        onAnimationFinished?()
    }

    static func totalDuration(count: Int, speed: AnimationSpeed, additionMode: AdditionMode = .collapse, finalSum: Int = 0) -> Double {
        guard count > 0 else { return 0 }
        let base = AnimationTiming()
        let timing = base.scaled(for: speed)
        let sumPause = speed == .fastest ? 0.05 : 0.3
        let completeDuration = speed == .fastest ? 0.05 : 0.2
        var totalDelay: Double = timing.flyOutDelay
        totalDelay += timing.flyOutDuration + timing.alignDelay
        totalDelay += timing.alignDuration + timing.pairDelay
        totalDelay += timing.pairDuration
        totalDelay += Double(count) * timing.productRevealDelay + timing.productRevealDuration
        totalDelay += timing.collapseDelay

        if additionMode == .longForm {
            // Long form: just collapse delay, then digits
            totalDelay += timing.collapseDelay
            totalDelay += timing.sumDelay
            totalDelay += timing.sumDuration
            // Digit reveal time
            let digitCount = max(1, String(abs(finalSum)).count)
            let digitDelay = speed == .fastest ? 0.08 : (speed == .fast ? 0.15 : 0.25)
            totalDelay += Double(digitCount) * digitDelay + 0.2
        } else {
            // Collapse mode
            if count > 1 {
                totalDelay += Double(count - 1) * timing.collapseStepDelay
                totalDelay += timing.collapseDuration
            }
            totalDelay += timing.sumDelay
            totalDelay += timing.sumDuration + sumPause
        }

        totalDelay += completeDuration + timing.flyToResultDelay
        totalDelay += timing.flyToResultDuration
        return totalDelay
    }

    private func pauseAwareSleep(seconds: Double) async {
        guard seconds > 0 else { return }
        var remaining = seconds
        let step = 0.05
        while remaining > 0 {
            if Task.isCancelled { return }
            if isPaused {
                await pauseUntilResumed()
            } else {
                let slice = min(step, remaining)
                let nanos = UInt64(slice * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanos)
                remaining -= slice
            }
        }
    }

    private func pauseUntilResumed() async {
        while isPaused {
            if Task.isCancelled { return }
            try? await Task.sleep(nanoseconds: 50_000_000)
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
            resultCellFrame: CGRect(x: 100, y: 400, width: 50, height: 50),
            speed: .normal,
            additionMode: .collapse,
            isPaused: .constant(false),
            onResultPlaced: nil,
            onAnimationFinished: nil
        )
    }
}
