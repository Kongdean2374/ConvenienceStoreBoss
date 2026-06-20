//
//  PrimaryButton.swift
//  ConvenienceStoreBoss
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var isEnabled: Bool = true
    var style: Style = .primary
    let action: () -> Void

    enum Style {
        case primary, secondary, danger, success
        var color: Color {
            switch self {
            case .primary: return .blue
            case .secondary: return .gray
            case .danger: return .red
            case .success: return .green
            }
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon { Image(systemName: icon) }
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(style.color.opacity(isEnabled ? 1 : 0.3))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!isEnabled)
    }
}

#Preview {
    PrimaryButton(title: "測試") { }
        .padding()
}
