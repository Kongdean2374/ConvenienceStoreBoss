//
//  UpgradeView.swift
//  ConvenienceStoreBoss
//
//  升級頁：顯示所有升級項目，可購買升級。
//

import SwiftUI

struct UpgradeView: View {
    @EnvironmentObject var vm: GameViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(vm.store.upgrades) { upgrade in
                    upgradeCard(upgrade)
                }
            }
            .padding()
        }
    }

    private func upgradeCard(_ upgrade: Upgrade) -> some View {
        let canAfford = vm.canAfford(upgrade.nextCost)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(upgrade.name).font(.headline)
                    Text(upgrade.description).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Lv.\(upgrade.level)/\(upgrade.maxLevel)")
                        .font(.caption).fontWeight(.bold).foregroundColor(.purple)
                    if upgrade.isMaxed {
                        Text("已滿級").font(.caption2).foregroundColor(.green)
                    }
                }
            }

            // 等級條
            HStack(spacing: 3) {
                ForEach(0..<upgrade.maxLevel, id: \.self) { i in
                    Rectangle()
                        .fill(i < upgrade.level ? Color.blue : Color.gray.opacity(0.2))
                        .frame(height: 6)
                        .cornerRadius(2)
                }
            }

            if upgrade.isMaxed {
                Text("已達最高等級").font(.caption).foregroundColor(.green)
            } else {
                Button {
                    _ = vm.buyUpgrade(type: upgrade.type)
                } label: {
                    HStack {
                        Label("升級", systemImage: "arrow.up.circle.fill")
                        Spacer()
                        Text("$\(upgrade.nextCost)")
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                    }
                    .padding(.vertical, 10).padding(.horizontal, 12)
                    .background(canAfford ? Color.blue : Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(!canAfford)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    UpgradeView().environmentObject(GameViewModel())
}
