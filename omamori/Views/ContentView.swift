//
//  ContentView.swift
//  omamori
//
//  Created by RickLiu1203 on 2026-04-23.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @State private var viewModel = SafetyViewModel()

    var body: some View {
        VStack(spacing: 0) {
            Map(position: $viewModel.mapCameraPosition) {
                UserAnnotation()
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .frame(height: UIScreen.main.bounds.height * 0.45)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    locationCard

                    Button {
                        Task { await viewModel.checkSafety() }
                    } label: {
                        HStack {
                            if viewModel.isLoadingSafety {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(viewModel.isLoadingSafety ? "Checking..." : "Check Safety")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.canCheckSafety ? Color.blue : Color.gray)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!viewModel.canCheckSafety)

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }

                    if let result = viewModel.safetyResult {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Safety Assessment")
                                .font(.headline)
                            Text(result)
                                .font(.body)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
        }
        .task {
            await viewModel.fetchLocation()
        }
    }

    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            if viewModel.isLoadingLocation {
                HStack {
                    ProgressView()
                    Text("Finding your location...")
                        .foregroundStyle(.secondary)
                }
            } else if let address = viewModel.fullAddress {
                Label(address, systemImage: "location.fill")
                    .font(.subheadline)
                if let coord = viewModel.userLocation?.coordinate {
                    Text("\(coord.latitude, specifier: "%.4f"), \(coord.longitude, specifier: "%.4f")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Label("Location unavailable", systemImage: "location.slash")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ContentView()
}
