//
//  BusinessView.swift
//  ConvenienceStoreBoss
//
//  經營頁：segmented control 切換 進貨/貨架/收銀/升級。
//

import SwiftUI

struct BusinessView: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var segment: Segment = .purchase

    enum Segment: String, CaseIterable, Identifiable {
        case purchase = "進貨"
        case shelf    = "貨架"
        case checkout = "收銀"
        case upgrade  = "升級"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("經營", selection: $segment) {
                    ForEach(Segment.allCases) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                switch segment {
                case .purchase: ProductListView(mode: .purchase)
                case .shelf:    ProductListView(mode: .shelf)
                case .checkout: CheckoutView()
                case .upgrade:  UpgradeView()
                }
            }
            .navigationTitle("經營")
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }
}

#Preview {
    BusinessView().environmentObject(GameViewModel())
}
