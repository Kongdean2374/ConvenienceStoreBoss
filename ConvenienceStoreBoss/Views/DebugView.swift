//
//  DebugView.swift
//  ConvenienceStoreBoss
//
//  Debug 頁：測試與修復資料。只有 settings.debugModeEnabled = true 時顯示。
//  注意：DebugView 是用來測試與修復資料，不是正常玩法的一部分。
//

import SwiftUI

struct DebugView: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var checkResults: [String] = []

    var body: some View {
        NavigationStack {
            Form {
                dataCheckSection
                repairSection
                testInjectSection
                productAnomalySection
                employeeAnomalySection
                logSection
            }
            .navigationTitle("Debug")
        }
    }

    // MARK: - 資料檢查

    private var dataCheckSection: some View {
        Section("資料完整性檢查") {
            Button {
                checkResults = vm.runDataIntegrityCheck()
                if checkResults.isEmpty { checkResults = ["✅ 沒有發現異常資料"] }
                vm.appendDebugLog("執行了資料完整性檢查。")
            } label: {
                Label("執行資料完整性檢查", systemImage: "stethoscope")
            }
            if !checkResults.isEmpty {
                ForEach(checkResults, id: \.self) { result in
                    Text(result)
                        .font(.caption)
                        .foregroundColor(result.hasPrefix("✅") ? .green : .orange)
                }
            }
        }
    }

    // MARK: - 修復

    private var repairSection: some View {
        Section("修復工具") {
            Button {
                vm.repairBrokenSave()
                checkResults = []
            } label: {
                Label("自動修復壞資料", systemImage: "wrench.and.screwdriver")
            }
            Button {
                vm.debugAddMoney()
            } label: {
                Label("給玩家 +10000 現金", systemImage: "dollarsign.circle")
            }
            Button {
                vm.debugFillWarehouse()
            } label: {
                Label("補滿全部倉庫", systemImage: "shippingbox.fill")
            }
            Button(role: .destructive) {
                vm.debugClearMoney()
            } label: {
                Label("清空現金（測試資金不足）", systemImage: "trash.circle")
            }
            Button(role: .destructive) {
                vm.debugClearShelves()
            } label: {
                Label("清空全部貨架", systemImage: "trash")
            }
            Button {
                vm.triggerTestEvent()
            } label: {
                Label("製造測試事件", systemImage: "ladybug")
            }
        }
    }

    // MARK: - 故意製造異常（測試修復能力）

    private var testInjectSection: some View {
        Section("測試用：故意製造異常資料") {
            Text("以下按鈕會故意寫入壞資料，用來測試修復功能。請勿在正常存檔使用。")
                .font(.caption).foregroundColor(.secondary)
            Button(role: .destructive) {
                vm.debugMakeNegativeStock()
            } label: {
                Label("製造負數庫存測試", systemImage: "exclamationmark.triangle")
            }
            Button(role: .destructive) {
                vm.debugMakeNegativeMoney()
            } label: {
                Label("製造負數資金測試", systemImage: "exclamationmark.triangle.fill")
            }
            Button {
                vm.repairBrokenSave()
                vm.appendDebugLog("已修復剛剛的測試異常資料。")
            } label: {
                Label("修復負數測試資料", systemImage: "checkmark.shield")
            }
        }
    }

    // MARK: - 商品異常

    private var productAnomalySection: some View {
        Section("商品異常狀態") {
            let anomalies = productAnomalies
            if anomalies.isEmpty {
                Text("✅ 商品資料正常").font(.caption).foregroundColor(.green)
            } else {
                ForEach(anomalies, id: \.self) { Text($0).font(.caption).foregroundColor(.orange) }
            }
        }
    }

    private var productAnomalies: [String] {
        var result: [String] = []
        for p in vm.store.products {
            if p.warehouseStock < 0 { result.append("\(p.name) 倉庫庫存 \(p.warehouseStock) < 0") }
            if p.shelfStock < 0 { result.append("\(p.name) 架上庫存 \(p.shelfStock) < 0") }
            if p.shelfStock > p.shelfCapacity { result.append("\(p.name) 架上 \(p.shelfStock) > 容量 \(p.shelfCapacity)") }
            if p.shelfCapacity < 0 { result.append("\(p.name) 容量 \(p.shelfCapacity) < 0") }
            if p.sellPrice < 1 { result.append("\(p.name) 售價 \(p.sellPrice) < 1") }
            if p.buyPrice < 0 { result.append("\(p.name) 進價 \(p.buyPrice) < 0") }
        }
        return result
    }

    // MARK: - 員工異常

    private var employeeAnomalySection: some View {
        Section("員工異常狀態") {
            let anomalies = employeeAnomalies
            if anomalies.isEmpty {
                Text("✅ 員工資料正常").font(.caption).foregroundColor(.green)
            } else {
                ForEach(anomalies, id: \.self) { Text($0).font(.caption).foregroundColor(.orange) }
            }
        }
    }

    private var employeeAnomalies: [String] {
        var result: [String] = []
        for e in vm.store.employees where e.hired {
            if !(0...100).contains(e.mood) { result.append("\(e.name) mood \(e.mood)") }
            if !(0...100).contains(e.fatigue) { result.append("\(e.name) fatigue \(e.fatigue)") }
            if !(0...100).contains(e.loyalty) { result.append("\(e.name) loyalty \(e.loyalty)") }
            if !(0...100).contains(e.quitRisk) { result.append("\(e.name) quitRisk \(e.quitRisk)") }
            if !(0...100).contains(e.lazyRisk) { result.append("\(e.name) lazyRisk \(e.lazyRisk)") }
            if e.hourlyWage < 0 { result.append("\(e.name) hourlyWage \(e.hourlyWage) < 0") }
        }
        return result
    }

    // MARK: - 日誌

    private var logSection: some View {
        Section("Debug Log") {
            if vm.store.debugLog.isEmpty {
                Text("尚無 Debug 紀錄").font(.caption).foregroundColor(.secondary)
            } else {
                ForEach(vm.store.debugLog.suffix(20).reversed(), id: \.self) { log in
                    Text(log).font(.caption2).foregroundColor(.secondary)
                }
            }
        }
        Section("最近 20 筆事件 Log") {
            ForEach(vm.store.eventLog.suffix(20).reversed(), id: \.self) { log in
                Text(log).font(.caption2).foregroundColor(.secondary)
            }
        }
    }
}
