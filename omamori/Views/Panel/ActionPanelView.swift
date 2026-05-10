//
//  ActionPanelView.swift
//  omamori
//
//  Created by RickLiu1203 on 2026-04-23.
//

import SwiftUI

struct ActionPanelView: View {
    @Bindable var viewModel: SafetyViewModel

    var body: some View {
        VStack(spacing: 16) {
            Picker("Mode", selection: $viewModel.selectedMode) {
                Text("Safety").tag(AssessmentMode.safety)
                Text("Liveability").tag(AssessmentMode.liveability)
            }
            .pickerStyle(.segmented)
            .disabled(viewModel.isLoadingSafety)

            LocationCardView(viewModel: viewModel)

            CheckSafetyButtonView(viewModel: viewModel)
        }
        .padding(16)
    }
}
