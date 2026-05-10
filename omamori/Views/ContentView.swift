//
//  ContentView.swift
//  omamori
//
//  Created by RickLiu1203 on 2026-04-23.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = SafetyViewModel()

    var body: some View {
        VStack(spacing: 0) {
            MapAreaView(viewModel: viewModel)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ActionPanelView(viewModel: viewModel)

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                    }

                    if let result = viewModel.safetyResult {
                        safetyCard(result)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                    }
                }
            }
        }
        .task {
            await viewModel.fetchLocation()
        }
    }

    // Temporary inline card — replaced by ResultsSheetView in Step 6
    private func safetyCard(_ result: SafetyAssessment) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(result.neighborhood)
                .font(.headline)

            HStack(alignment: .firstTextBaseline) {
                Text(String(format: "%.1f", result.safetyScore))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                Text("/ 10")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Divider()

            let sub = result.safetyCategories
            categoryRow("creditcard.trianglebadge.exclamationmark.fill", "Scams & Fraud",    sub.scamsAndFraud)
            categoryRow("moon.fill",                                      "Night Safety",     sub.nightSafety)
            categoryRow("bus.fill",                                       "Transportation",   sub.transportationSafety)
            categoryRow("bag.fill",                                       "Petty Theft",      sub.pettyTheft)
            categoryRow("hand.raised.fill",                               "Robbery",          sub.robbery)
            categoryRow("figure.boxing",                                  "Assault",          sub.assault)
            categoryRow("exclamationmark.bubble.fill",                    "Sexual Harassment", sub.sexualHarassment)
            categoryRow("person.fill.xmark",                              "Hate Crime",       sub.hateCrime)
            categoryRow("road.lanes",                                     "Street Safety",    sub.streetSafety)

            let warn = result.warnings
            let threshold = SafetyAssessment.warningThreshold
            if warn.soloTravel.rating <= threshold || warn.femaleTravel.rating <= threshold || warn.lgbtqTravel.rating <= threshold {
                Divider()
                if warn.soloTravel.rating <= threshold {
                    categoryRow("figure.walk", "Solo Travel", warn.soloTravel)
                        .padding(8)
                        .background(Color.orange.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                if warn.femaleTravel.rating <= threshold {
                    categoryRow("figure.dress.line.vertical.figure", "Female Travel", warn.femaleTravel)
                        .padding(8)
                        .background(Color.orange.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                if warn.lgbtqTravel.rating <= threshold {
                    categoryRow("rainbow", "LGBTQ+ Travel", warn.lgbtqTravel)
                        .padding(8)
                        .background(Color.orange.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func categoryRow(_ icon: String, _ name: String, _ category: SafetyAssessment.Category) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 20)
                Text(name)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(category.rating)/10")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }
            Text(category.headline)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
}
