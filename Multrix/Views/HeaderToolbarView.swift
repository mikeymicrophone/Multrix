//
//  HeaderToolbarView.swift
//  Multrix
//

import SwiftUI

struct HeaderToolbarView: View {
    let isAnimating: Bool
    let isPaused: Bool
    let onPauseTapped: () -> Void
    let onSettingsTapped: () -> Void

    var body: some View {
        HStack {
            Spacer()

            if isAnimating {
                pauseButton
            }

            settingsButton
        }
    }

    // MARK: - Subviews

    private var pauseButton: some View {
        Button(action: onPauseTapped) {
            Image(systemName: isPaused ? "play.fill" : "pause.fill")
                .font(.title3)
                .foregroundColor(.white)
                .padding(8)
                .background(Color.orange)
                .clipShape(Circle())
        }
        .accessibilityIdentifier("toolbar.pause")
    }

    private var settingsButton: some View {
        Button(action: onSettingsTapped) {
            Image(systemName: "gearshape")
                .font(.title3)
                .foregroundColor(.blue)
                .padding(8)
        }
        .accessibilityLabel("Preferences")
        .accessibilityIdentifier("toolbar.preferences")
    }
}

// MARK: - Previews

#Preview("Not Animating") {
    HeaderToolbarView(
        isAnimating: false,
        isPaused: false,
        onPauseTapped: {},
        onSettingsTapped: {}
    )
    .padding()
}

#Preview("Animating - Playing") {
    HeaderToolbarView(
        isAnimating: true,
        isPaused: false,
        onPauseTapped: {},
        onSettingsTapped: {}
    )
    .padding()
}

#Preview("Animating - Paused") {
    HeaderToolbarView(
        isAnimating: true,
        isPaused: true,
        onPauseTapped: {},
        onSettingsTapped: {}
    )
    .padding()
}
