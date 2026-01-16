//
//  MatrixFlowUITests.swift
//  MultrixUITests
//
//  Created by Codex on 3/8/25.
//

import XCTest

final class MatrixFlowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testFillMissingCellsAndCalculate() {
        fillFirstEmptyCell(in: 0, withDigit: "1")
        fillFirstEmptyCell(in: 1, withDigit: "1")

        let multiplyButton = app.buttons["calculate.multiply"]
        XCTAssertTrue(multiplyButton.waitForExistence(timeout: 2))
        let enabledExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "enabled == true"),
            object: multiplyButton
        )
        XCTAssertEqual(XCTWaiter().wait(for: [enabledExpectation], timeout: 2), .completed)
        multiplyButton.tap()

        let resultMatrix = app.otherElements["result.matrix"]
        if !resultMatrix.waitForExistence(timeout: 2) {
            scrollToElement(resultMatrix)
        }
        XCTAssertTrue(resultMatrix.exists)

        let resultCells = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "result.cell."))
        let firstResultCell = resultCells.element(boundBy: 0)
        if !firstResultCell.waitForExistence(timeout: 2) || !firstResultCell.isHittable {
            scrollToElement(firstResultCell)
        }
        XCTAssertTrue(firstResultCell.exists)
        firstResultCell.tap()

        let breakdown = app.otherElements["result.breakdown"]
        XCTAssertTrue(breakdown.waitForExistence(timeout: 2))
    }

    private func fillFirstEmptyCell(in matrixIndex: Int, withDigit digit: String) {
        let prefix = "matrix.\(matrixIndex).cell."
        let cells = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", prefix))

        if cells.count == 0 {
            XCTFail("No cells found for matrix \(matrixIndex)")
            return
        }

        for index in 0..<cells.count {
            let cell = cells.element(boundBy: index)
            let label = cell.label.lowercased()
            let value = (cell.value as? String)?.lowercased() ?? ""
            if label.contains("empty") || value.contains("empty") {
                cell.tap()

                let input = app.otherElements["numberInput.container"]
                XCTAssertTrue(input.waitForExistence(timeout: 2))

                let digitButton = app.buttons["numberInput.digit.\(digit)"]
                XCTAssertTrue(digitButton.waitForExistence(timeout: 2))
                digitButton.tap()
                return
            }
        }

        XCTContext.runActivity(named: "Matrix \(matrixIndex) cell labels (sample)") { _ in
            let maxSamples = min(12, cells.count)
            for index in 0..<maxSamples {
                let cell = cells.element(boundBy: index)
                print("cell[\(index)] id=\(cell.identifier) label=\(cell.label) value=\(String(describing: cell.value))")
            }
        }

        XCTFail("No empty cell found in matrix \(matrixIndex)")
    }

    private func scrollToElement(_ element: XCUIElement, maxSwipes: Int = 4) {
        let scrollView = app.scrollViews.firstMatch
        guard scrollView.exists else { return }

        for _ in 0..<maxSwipes {
            if element.exists && element.isHittable { return }
            scrollView.swipeUp()
        }
    }
}
