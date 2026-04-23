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
            ZStack {
                Map(position: $viewModel.mapCameraPosition) {
                    UserAnnotation()
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                }
                .onMapCameraChange(frequency: .continuous) { _ in
                    viewModel.onCameraMoving()
                }
                .onMapCameraChange(frequency: .onEnd) { context in
                    viewModel.scheduleCameraUpdate(center: context.camera.centerCoordinate)
                }

                if !viewModel.isUsingCurrentLocation {
                    Image(systemName: "mappin")
                        .font(.system(size: 28))
                        .foregroundStyle(.red)
                        .opacity(viewModel.isPinSettled ? 1.0 : 0.4)
                        .offset(y: viewModel.isPinSettled ? -14 : -24)
                        .scaleEffect(viewModel.isPinSettled ? 1.0 : 0.85)
                        .animation(.spring(duration: 0.35, bounce: 0.5), value: viewModel.isPinSettled)
                }
            }
            .frame(height: UIScreen.main.bounds.height * 0.45)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !viewModel.isUsingCurrentLocation {
                        Button {
                            Task { await viewModel.returnToCurrentLocation() }
                        } label: {
                            Label("Return to My Location", systemImage: "location")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding(10)
                                .background(Color(.systemGray5))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }

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
                Label(address, systemImage: viewModel.isUsingCurrentLocation ? "location.fill" : "mappin.and.ellipse")
                    .font(.subheadline)
                if let coord = viewModel.activeCoordinate {
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
