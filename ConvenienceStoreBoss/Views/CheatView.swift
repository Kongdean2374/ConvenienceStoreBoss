//
//  CheatView.swift
//  ConvenienceStoreBoss
//
//  外掛頁：所有作弊選項。開啟任一外掛即標記為外掛存檔。
//

import SwiftUI

struct CheatView: View {
    @EnvironmentObject var vm: GameViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("警告", systemImage: "exclamationmark.triangle.fill")
                        .font(.headline).foregroundColor(.orange)
                    Text("開啟任何外掛後，這個存檔會被標記為「外掛存檔」，且無法恢復為正常存檔狀態。")
                        .font(.caption).foregroundColor(.secondary)
                    if vm.store.isCheatSave {
                        Label("目前為外掛存檔", systemImage: "wand.and.stars")
                            .font(.caption).foregroundColor(.orange)
                    }
                }
                .padding(.vertical, 4)
            } header: { Text("外掛警告") }

            Section("基本外掛") {
                Toggle("外掛總開關", isOn: cheatBinding(\.cheatModeEnabled))
                Toggle("無限金錢", isOn: cheatBinding(\.infiniteMoney))
                Toggle("商品永不過期", isOn: cheatBinding(\.productsNeverExpire))
                Toggle("員工永不離職", isOn: cheatBinding(\.employeesNeverQuit))
                Toggle("員工永遠滿意", isOn: cheatBinding(\.employeesAlwaysHappy))
                Toggle("客人永遠滿意", isOn: cheatBinding(\.customersAlwaysSatisfied))
                Toggle("所有事件必定成功", isOn: cheatBinding(\.eventsAlwaysSuccess))
                Toggle("店鋪名聲鎖定 100", isOn: cheatBinding(\.maxReputationLocked))
            }

            Section("倍率") {
                Picker("金錢倍率", selection: moneyMultBinding) {
                    Text("1x").tag(1.0)
                    Text("2x").tag(2.0)
                    Text("5x").tag(5.0)
                    Text("10x").tag(10.0)
                    Text("100x").tag(100.0)
                }
                Picker("客流量倍率", selection: customerMultBinding) {
                    Text("1x").tag(1.0)
                    Text("2x").tag(2.0)
                    Text("5x").tag(5.0)
                    Text("10x").tag(10.0)
                }
            }

            Section("解鎖") {
                Toggle("解鎖全部商品", isOn: cheatBinding(\.allProductsUnlocked))
                Toggle("解鎖全部員工", isOn: cheatBinding(\.allEmployeesUnlocked))
            }

            Section("一鍵補滿") {
                Toggle("自動補滿全部倉庫", isOn: cheatBinding(\.autoFillWarehouse))
                Toggle("自動補滿全部貨架", isOn: cheatBinding(\.autoFillShelves))
                Button {
                    vm.cheatFillAllWarehouse()
                } label: {
                    Label("立即補滿全部倉庫", systemImage: "shippingbox.fill")
                }
                Button {
                    vm.cheatFillAllShelves()
                } label: {
                    Label("立即補滿全部貨架", systemImage: "square.stack.3d.up.fill")
                }
            }
        }
        .navigationTitle("外掛模式")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("完成") { dismiss() }
            }
        }
    }

    // MARK: - Bindings

    private func cheatBinding(_ keyPath: WritableKeyPath<CheatSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { vm.store.cheats[keyPath: keyPath] },
            set: { newValue in vm.updateCheats { $0[keyPath: keyPath] = newValue } }
        )
    }

    private var moneyMultBinding: Binding<Double> {
        Binding(
            get: { vm.store.cheats.moneyMultiplier },
            set: { newValue in vm.updateCheats { $0.moneyMultiplier = newValue } }
        )
    }

    private var customerMultBinding: Binding<Double> {
        Binding(
            get: { vm.store.cheats.customerMultiplier },
            set: { newValue in vm.updateCheats { $0.customerMultiplier = newValue } }
        )
    }
}
