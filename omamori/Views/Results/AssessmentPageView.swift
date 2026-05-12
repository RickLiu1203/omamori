//
//  AssessmentPageView.swift
//  omamori
//

import SwiftUI

struct AssessmentPageView: View {
    var viewModel: SafetyViewModel

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                if !viewModel.activeWarnings.isEmpty {
                    WarningsSectionView(warnings: viewModel.activeWarnings)
                }

                TopRisksView(
                    title: viewModel.currentTopRisksTitle,
                    items: viewModel.currentTopRisks
                )

                if !viewModel.naturalDisasterConcerns.isEmpty {
                    NaturalDisasterConcernsView(concerns: viewModel.naturalDisasterConcerns)
                }

                BreakdownView(categories: viewModel.currentCategories)
            }
            .padding(16)
        }
    }
}
