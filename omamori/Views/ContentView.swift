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
                ActionPanelView(viewModel: viewModel)
            }
        }
        .overlay(alignment: .top) {
            if let msg = viewModel.toastMessage {
                ToastView(message: msg)
                    .padding(.top, 12)
            }
        }
        .animation(.spring, value: viewModel.toastMessage)
        .sheet(isPresented: $viewModel.isResultsSheetPresented) {
            ResultsSheetView(viewModel: viewModel)
                .presentationDetents([.fraction(0.85), .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
                .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.85)))
        }
        .task {
            await viewModel.fetchLocation()
        }
    }
}

#Preview {
    ContentView()
}
