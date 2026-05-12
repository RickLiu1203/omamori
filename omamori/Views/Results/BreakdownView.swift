//
//  BreakdownView.swift
//  omamori
//

import SwiftUI

struct BreakdownView: View {
    let categories: [CategoryDisplayItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Breakdown")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(categories) { item in
                    CategoryRowView(item: item)
                }
            }
        }
    }
}

#Preview {
    BreakdownView(categories: [
        CategoryDisplayItem(id: "pettyTheft", icon: "bag.fill", name: "Petty Theft", rating: 4, headline: "Common in tourist areas"),
        CategoryDisplayItem(id: "nightSafety", icon: "moon.fill", name: "Night Safety", rating: 7, headline: "Mostly safe after dark"),
        CategoryDisplayItem(id: "scamsAndFraud", icon: "creditcard.trianglebadge.exclamationmark.fill", name: "Scams & Fraud", rating: 5, headline: "Watch for tourist traps"),
    ])
    .padding()
}
