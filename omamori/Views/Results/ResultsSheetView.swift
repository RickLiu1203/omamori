//
//  ResultsSheetView.swift
//  omamori
//

import SwiftUI

struct ResultsSheetView: View {
    @Bindable var viewModel: SafetyViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text(viewModel.sheetHeaderTitle)
                .font(.headline)
                .padding(.top, 20)
                .padding(.bottom, 16)

            // Score ring + score number
            ZStack {
                ScoreRingView(fraction: viewModel.scoreFraction, color: viewModel.scoreColor)

                VStack(spacing: 2) {
                    Text(String(format: "%.1f", viewModel.scoreFraction * 10))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(viewModel.scoreColor)
                    Text(viewModel.scoreLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.bottom, 12)

            // Custom page indicator
            HStack(spacing: 6) {
                ForEach(AssessmentMode.allCases, id: \.self) { mode in
                    Capsule()
                        .fill(viewModel.selectedMode == mode ? Color.primary : Color(.systemGray4))
                        .frame(width: viewModel.selectedMode == mode ? 16 : 6, height: 6)
                        .animation(.spring(duration: 0.3), value: viewModel.selectedMode)
                }
            }
            .padding(.bottom, 8)

            Text(viewModel.selectedMode == .safety ? "Safety" : "Liveability")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 12)

            Divider()

            // Swipeable content pages
            TabView(selection: $viewModel.selectedMode) {
                AssessmentPageView(viewModel: viewModel)
                    .tag(AssessmentMode.safety)

                AssessmentPageView(viewModel: viewModel)
                    .tag(AssessmentMode.liveability)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
}
