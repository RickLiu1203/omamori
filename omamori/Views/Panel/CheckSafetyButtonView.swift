//
//  CheckSafetyButtonView.swift
//  omamori
//
//  Created by RickLiu1203 on 2026-04-23.
//

import SwiftUI

struct CheckSafetyButtonView: View {
    var viewModel: SafetyViewModel

    var body: some View {
        VStack(spacing: 8) {
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                Task { await viewModel.requestSafetyCheck() }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isLoadingSafety {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(viewModel.isLoadingSafety ? "Checking..." : "Check Safety")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!viewModel.canCheckSafety)

            if viewModel.isLoadingSafety {
                if let phase = viewModel.loadingPhase {
                    Text(phase)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ProgressView()
                    .progressViewStyle(.linear)
                    .tint(.blue)
            }
        }
    }
}
