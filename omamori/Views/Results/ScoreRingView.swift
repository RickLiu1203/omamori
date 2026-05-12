//
//  ScoreRingView.swift
//  omamori
//

import SwiftUI

struct ScoreRingView: View {
    let fraction: Double
    let color: Color

    private let lineWidth: CGFloat = 12
    private let diameter: CGFloat = 120

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: max(0, min(fraction, 1)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: fraction)
        }
        .frame(width: diameter, height: diameter)
    }
}

#Preview {
    HStack(spacing: 24) {
        ScoreRingView(fraction: 0.3, color: .red)
        ScoreRingView(fraction: 0.6, color: .yellow)
        ScoreRingView(fraction: 0.9, color: .green)
    }
    .padding()
}
