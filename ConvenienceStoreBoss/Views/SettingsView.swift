//
//  SettingsView.swift
//  ConvenienceStoreBoss
//
//  設定頁：一般 / 遊戲 / 老闆 / 外掛入口 / Debug / 資料管理。
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var showCheat = false
    @State private var showExport = false
    @State private var importText = ""
    @State private var showImport = false

    var body: some View {
        NavigationStack {
            Form {
                generalSection
                gameSection
                bossSection
                cheatEntrySection
                debugSection
                dataSection
                aboutSection
            }
            .navigationTitle("設定")
        }
        .sheet(isPresented: $showCheat) {
            NavigationStack {
                CheatView().environmentObject(vm)
            }
        }
        .sheet(isPresented: $showExport) {
            ExportSheet(text: vm.exportSave())
        }
        .sheet(isPresented: $showImport) {
            ImportSheet(text: $importText) {
                if vm.importSave(importText) {
                    showImport = false
                }
            }
        }
    }

    // MARK: - 一般設定

    private var generalSection: some View {
        Section("一般設定") {
            Toggle("音效", isOn: binding(\.soundEnabled))
            Toggle("震動", isOn: binding(\.hapticEnabled))
            Toggle("自動存檔", isOn: binding(\.autoSaveEnabled))
            HStack {
                Label("深色模式", systemImage: "moon")
                Spacer()
                Text("跟隨系統").foregroundColor(.secondary).font(.caption)
            }
        }
    }

    // MARK: - 遊戲設定

    private var gameSection: some View {
        Section("遊戲設定") {
            Picker("遊戲速度", selection: speedBinding) {
                Text("0.5x").tag(0.5)
                Text("1x").tag(1.0)
                Text("2x").tag(2.0)
                Text("5x").tag(5.0)
                Text("10x").tag(10.0)
            }
            Picker("事件頻率", selection: binding(\.eventFrequency)) {
                ForEach(EventFrequency.allCases) { Text($0.rawValue).tag($0) }
            }
            Picker("難度", selection: binding(\.difficulty)) {
                ForEach(Difficulty.allCases) { Text($0.rawValue).tag($0) }
            }
            Toggle("補貨提醒", isOn: binding(\.showRestockWarning))
            Toggle("薪資提醒", isOn: binding(\.showSalaryWarning))
            Toggle("客訴提醒", isOn: binding(\.showCustomerComplaintWarning))
        }
    }

    // MARK: - 老闆設定

    private var bossSection: some View {
        Section("老闆設定") {
            HStack {
                Text("預設售價倍率")
                Spacer()
                Text(String(format: "%.1fx", vm.store.settings.defaultPriceMultiplier)).foregroundColor(.blue)
            }
            Stepper("自動補貨警戒線：\(vm.store.settings.autoRestockThresholdPercent)%",
                    value: binding(\.autoRestockThresholdPercent), in: 5...80, step: 5)
            Stepper("自動補貨數量：\(vm.store.settings.autoRestockAmount)",
                    value: binding(\.autoRestockAmount), in: 1...50, step: 1)
            Stepper("最低薪資提醒：$\(vm.store.settings.minWageReminder)",
                    value: binding(\.minWageReminder), in: 0...500, step: 10)
            Toggle("允許員工自動補貨", isOn: binding(\.allowEmployeeAutoRestock))
            Toggle("允許店長自動處理小事件", isOn: binding(\.allowManagerAutoHandleEvents))
        }
    }

    // MARK: - 外掛入口

    private var cheatEntrySection: some View {
        Section("外掛模式") {
            Button {
                showCheat = true
            } label: {
                Label("進入外掛模式", systemImage: "wand.and.stars")
                    .foregroundColor(.orange)
            }
            if vm.store.isCheatSave {
                Label("此存檔已被標記為外掛存檔", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption).foregroundColor(.orange)
            }
        }
    }

    // MARK: - Debug

    private var debugSection: some View {
        Section("Debug 模式") {
            Toggle("開啟 Debug 模式", isOn: binding(\.debugModeEnabled))
            if vm.store.settings.debugModeEnabled {
                Text("Debug 分頁已顯示於底部 Tab").font(.caption).foregroundColor(.secondary)
            }
        }
    }

    // MARK: - 資料管理

    private var dataSection: some View {
        Section("資料管理") {
            Button { vm.manualSave() } label: { Label("手動存檔", systemImage: "tray.and.arrow.down") }
            Button { vm.reloadSave() } label: { Label("重新讀取存檔", systemImage: "arrow.clockwise") }
            Button { showExport = true } label: { Label("匯出存檔文字", systemImage: "square.and.arrow.up") }
            Button { importText = ""; showImport = true } label: { Label("匯入存檔文字", systemImage: "square.and.arrow.down") }
            Button(role: .destructive) {
                vm.resetGame()
            } label: {
                Label("重置遊戲", systemImage: "trash")
            }
        }
    }

    // MARK: - 關於

    private var aboutSection: some View {
        Section("關於") {
            HStack { Text("App 名稱"); Spacer(); Text("便利店老闆模擬器").foregroundColor(.secondary) }
            HStack { Text("版本"); Spacer(); Text("1.0.0").foregroundColor(.secondary) }
            HStack { Text("平台"); Spacer(); Text("iOS 17+").foregroundColor(.secondary) }
        }
    }

    // MARK: - Bindings

    private func binding<T>(_ keyPath: WritableKeyPath<GameSettings, T>) -> Binding<T> {
        Binding(
            get: { vm.store.settings[keyPath: keyPath] },
            set: { newValue in vm.updateSettings { $0[keyPath: keyPath] = newValue } }
        )
    }

    private var speedBinding: Binding<Double> {
        Binding(
            get: { vm.store.settings.gameSpeed },
            set: { newValue in vm.updateSettings { $0.gameSpeed = newValue } }
        )
    }
}

// MARK: - Export / Import Sheets

private struct ExportSheet: View {
    let text: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(text)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .textSelection(.enabled)
            }
            .navigationTitle("匯出存檔")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

private struct ImportSheet: View {
    @Binding var text: String
    let onImport: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                TextEditor(text: $text)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
            }
            .navigationTitle("匯入存檔")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("匯入") { onImport() }
                }
            }
        }
    }
}

#Preview {
    SettingsView().environmentObject(GameViewModel())
}
