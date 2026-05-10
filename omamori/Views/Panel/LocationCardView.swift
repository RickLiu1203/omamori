//
//  LocationCardView.swift
//  omamori
//
//  Created by RickLiu1203 on 2026-04-23.
//

import SwiftUI

struct LocationCardView: View {
    var viewModel: SafetyViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if viewModel.isLoadingLocation {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Finding your location...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else if let address = viewModel.fullAddress {
                Label(
                    address,
                    systemImage: viewModel.isUsingCurrentLocation ? "location.fill" : "mappin.and.ellipse"
                )
                .font(.subheadline)
                if let coord = viewModel.activeCoordinate {
                    Text("\(coord.latitude, specifier: "%.4f"), \(coord.longitude, specifier: "%.4f")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Label("No address found", systemImage: "location.slash")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let coord = viewModel.activeCoordinate {
                    Text("\(coord.latitude, specifier: "%.4f"), \(coord.longitude, specifier: "%.4f")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
