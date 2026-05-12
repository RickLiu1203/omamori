//
//  CategoryRowView.swift
//  omamori
//

import SwiftUI

struct CategoryRowView: View {
    let item: CategoryDisplayItem

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                Image(systemName: item.icon)
                    .frame(width: 20)
                    .foregroundStyle(.secondary)
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
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack {
        CategoryRowView(item: CategoryDisplayItem(
            id: "pettyTheft",
            icon: "bag.fill",
            name: "Petty Theft",
            rating: 4,
            headline: "Pickpocketing common in tourist areas"
        ))
        CategoryRowView(item: CategoryDisplayItem(
            id: "nightSafety",
            icon: "moon.fill",
            name: "Night Safety",
            rating: 8,
            headline: "Generally safe after dark"
        ))
    }
    .padding()
}
