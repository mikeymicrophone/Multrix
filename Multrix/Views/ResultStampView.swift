//
//  ResultStampView.swift
//  Multrix
//

import SwiftUI

struct ResultStampView: View {
    let value: Int
    let frame: CGRect

    var body: some View {
        Text("\(value)")
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(width: 50, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.green.opacity(0.9))
            )
            .scaleEffect(0.9)
            .position(x: frame.midX, y: frame.midY)
    }
}

// MARK: - Previews

#Preview("Single Digit") {
    ZStack {
        Color.gray.opacity(0.1)
        ResultStampView(
            value: 5,
            frame: CGRect(x: 100, y: 100, width: 50, height: 50)
        )
    }
    .frame(width: 200, height: 200)
}

#Preview("Two Digits") {
    ZStack {
        Color.gray.opacity(0.1)
        ResultStampView(
            value: 42,
            frame: CGRect(x: 100, y: 100, width: 50, height: 50)
        )
    }
    .frame(width: 200, height: 200)
}

#Preview("Large Number") {
    ZStack {
        Color.gray.opacity(0.1)
        ResultStampView(
            value: 12345,
            frame: CGRect(x: 100, y: 100, width: 50, height: 50)
        )
    }
    .frame(width: 200, height: 200)
}

#Preview("Multiple Stamps") {
    ZStack {
        Color.gray.opacity(0.1)
        ResultStampView(value: 10, frame: CGRect(x: 50, y: 50, width: 50, height: 50))
        ResultStampView(value: 200, frame: CGRect(x: 110, y: 50, width: 50, height: 50))
        ResultStampView(value: 3000, frame: CGRect(x: 50, y: 110, width: 50, height: 50))
        ResultStampView(value: 40000, frame: CGRect(x: 110, y: 110, width: 50, height: 50))
    }
    .frame(width: 200, height: 200)
}
