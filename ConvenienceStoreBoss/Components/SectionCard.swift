//
//  SectionCard.swift
//

import SwiftUI

struct SectionCard<Content: View>: View {
    let title: String
    var icon: String? = nil
    let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let icon {
                    Image(systemName: icon).foregroundColor(.blue)
                }
                Text(title).font(.headline)
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    SectionCard(title: "區塊", icon: "box") {
        Text("內容")
    }
    .padding()
}
