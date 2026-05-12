//
//  ToastView.swift
//  omamori
//

import SwiftUI

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(radius: 4)
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
    }
}

#Preview {
    VStack {
        ToastView(message: "Unable to get location. Please try again.")
        Spacer()
    }
    .padding(.top, 20)
}
