//
//  TopRisksView.swift
//  omamori
//

import SwiftUI

struct TopRisksView: View {
    let title: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(items, id: \.self) { item in
                    Text("• \(item)")
                        .font(.subheadline)
                }
            }
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 24) {
        TopRisksView(title: "Top Safety Risks", items: [
            "Pickpocketing in tourist areas",
            "Taxi scams near the airport"
        ])
        TopRisksView(title: "Key Highlights", items: [
            "Excellent metro coverage",
            "Very walkable neighbourhood"
        ])
    }
    .padding()
}
