//
//  StatCard.swift
//

import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    var icon: String? = nil
    var color: Color = .blue
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if let icon {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 14, weight: .bold))
                }
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    StatCard(title: "現金", value: "5000", icon: "dollarsign.circle", color: .green)
        .padding()
}
