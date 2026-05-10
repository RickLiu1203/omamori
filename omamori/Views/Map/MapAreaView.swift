//
//  MapAreaView.swift
//  omamori
//

import SwiftUI
import MapKit

struct MapAreaView: View {
    @Bindable var viewModel: SafetyViewModel

    var body: some View {
        ZStack {
            Map(position: $viewModel.mapCameraPosition) {
                UserAnnotation()
            }
            .mapControls {
                MapCompass()
            }
            .onMapCameraChange(frequency: .continuous) { _ in
                viewModel.onCameraMoving()
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                viewModel.scheduleCameraUpdate(center: context.camera.centerCoordinate)
            }
            .onTapGesture {
                viewModel.isResultsSheetPresented = false
            }

            if viewModel.isDragging || !viewModel.isUsingCurrentLocation {
                Image(systemName: "mappin")
                    .font(.system(size: 28))
                    .foregroundStyle(.red)
                    .opacity(viewModel.isPinSettled ? 1.0 : 0.4)
                    .offset(y: viewModel.isPinSettled ? -14 : -24)
                    .scaleEffect(viewModel.isPinSettled ? 1.0 : 0.85)
                    .animation(.spring(duration: 0.35, bounce: 0.5), value: viewModel.isPinSettled)
            }

            if !viewModel.isUsingCurrentLocation {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            Task { await viewModel.returnToCurrentLocation() }
                        } label: {
                            Image(systemName: "location.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.blue)
                                .padding(10)
                                .background(.regularMaterial)
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                        .padding(.trailing, 12)
                        .padding(.bottom, 12)
                    }
                }
            }
        }
        .frame(height: UIScreen.main.bounds.height * 0.55)
    }
}
