//
//  ProgressStatView.swift
//  ConvenienceStoreBoss
//
//  顯示一個帶進度條的數值統計（0~100），用於名聲、滿意度、清潔度、心情等。
//

import SwiftUI

struct ProgressStatView: View {
    let title: String
    let value: Int          // 0~100
    var icon: String? = nil
    var color: Color = .blue
    var showNumber: Bool = true

    private var progressRatio: CGFloat {
        CGFloat(Double(min(100, max(0, value))) / 100.0)
    }

    /// 依數值自動給予顏色（高=綠、中=橘、低=紅）。可覆寫。
    private var displayColor: Color {
        if color != .blue { return color }
        switch value {
        case 70...100: return .green
        case 40..<70:  return .orange
        default:       return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let icon {
                    Image(systemName: icon)
                        .foregroundColor(displayColor)
                        .frame(width: 18)
                }
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
                if showNumber {
                    Text("\(value)")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(displayColor)
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 8)
                    Capsule()
                        .fill(displayColor)
                        .frame(width: geo.size.width * progressRatio, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(.vertical, 4)
    }
}

#Preview("ProgressStatView") {
    VStack(spacing: 16) {
        ProgressStatView(title: "店鋪名聲", value: 85, icon: "star.fill")
        ProgressStatView(title: "顧客滿意度", value: 55, icon: "smiley")
        ProgressStatView(title: "清潔度", value: 25, icon: "sparkles")
    }
    .padding()
}
