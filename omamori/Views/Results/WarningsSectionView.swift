//
//  WarningsSectionView.swift
//  omamori
//

import SwiftUI

struct WarningsSectionView: View {
    let warnings: [WarningDisplayItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("⚠ Heads Up")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.orange)
                .textCase(.uppercase)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(warnings) { item in
                    WarningRowView(item: item)
                }
            }
        }
    }
}

#Preview {
    WarningsSectionView(warnings: [
        WarningDisplayItem(id: "soloTravel", icon: "figure.walk", name: "Solo Travel", rating: 4, headline: "Exercise caution when alone at night"),
        WarningDisplayItem(id: "femaleTravel", icon: "figure.dress.line.vertical.figure", name: "Female Travel", rating: 3, headline: "Harassment reported in certain districts"),
    ])
    .padding()
}
