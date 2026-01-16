//
//  MatrixTests.swift
//  MultrixTests
//
//  Created by Codex on 3/8/25.
//

import Testing
@testable import Multrix

@Suite("NumberComplexity")
struct NumberComplexityTests {
    @Test(arguments: [
        (NumberComplexity.basic, "Basic", "Most numbers under 5"),
        (NumberComplexity.moderate, "Moderate", "Numbers 0-9"),
        (NumberComplexity.significant, "Significant", "Some 2-digit numbers"),
        (NumberComplexity.ultra, "Ultra", "Numbers 0-99"),
    ])
    func titleAndDescription(mapping: (NumberComplexity, String, String)) {
        #expect(mapping.0.title == mapping.1)
        #expect(mapping.0.description == mapping.2)
    }

    @Test("randomValue stays in expected range")
    func randomValueRange() {
        for complexity in NumberComplexity.allCases {
            for _ in 0..<100 {
                let value = complexity.randomValue()
                switch complexity {
                case .basic, .moderate:
                    #expect((0...9).contains(value))
                case .significant:
                    #expect((0...99).contains(value))
                case .ultra:
                    #expect((0...99).contains(value))
                }
            }
        }
    }
}

@Suite("Matrix")
struct MatrixTests {
    @Test("initializer creates one missing cell and correct dimensions")
    func initHasSingleNil() {
        let rows = 3
        let cols = 4
        let matrix = Matrix(rows: rows, cols: cols, complexity: .moderate)

        #expect(matrix.values.count == rows)
        #expect(matrix.values.allSatisfy { $0.count == cols })

        let nilCount = matrix.values.flatMap { $0 }.filter { $0 == nil }.count
        #expect(nilCount == 1)
    }

    @Test("isComplete reflects when values are filled")
    func isCompleteTracksValues() {
        var matrix = Matrix(rows: 2, cols: 2, complexity: .basic)
        #expect(matrix.isComplete == false)

        matrix.values = Array(repeating: Array(repeating: 1, count: 2), count: 2)
        #expect(matrix.isComplete == true)

        matrix.values[1][1] = nil
        #expect(matrix.isComplete == false)
    }
}
