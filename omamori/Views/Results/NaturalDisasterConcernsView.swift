//
//  NaturalDisasterConcernsView.swift
//  omamori
//

import SwiftUI

struct NaturalDisasterConcernsView: View {
    let concerns: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Natural Hazards")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(concerns, id: \.self) { concern in
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Text(concern)
                            .font(.subheadline)
                    }
                }
            }
        }
    }
}

#Preview {
    NaturalDisasterConcernsView(concerns: [
        "Earthquake zone (Seismic Zone 4)",
        "Seasonal flooding (Nov–Mar)",
        "Wildfire risk in surrounding hills"
    ])
    .padding()
}
