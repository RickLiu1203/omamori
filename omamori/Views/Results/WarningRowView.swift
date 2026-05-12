//
//  WarningRowView.swift
//  omamori
//

import SwiftUI

struct WarningRowView: View {
    let item: WarningDisplayItem

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                Image(systemName: item.icon)
                    .frame(width: 20)
                    .foregroundStyle(.orange)
                Text(item.name)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(item.rating)/10")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }
            Text(item.headline)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(8)
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack {
        WarningRowView(item: WarningDisplayItem(
            id: "soloTravel",
            icon: "figure.walk",
            name: "Solo Travel",
            rating: 4,
            headline: "Exercise caution when traveling alone at night"
        ))
        WarningRowView(item: WarningDisplayItem(
            id: "femaleTravel",
            icon: "figure.dress.line.vertical.figure",
            name: "Female Travel",
            rating: 3,
            headline: "Harassment reported in certain areas"
        ))
    }
    .padding()
}
