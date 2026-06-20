//
//  DashboardView.swift
//  ConvenienceStoreBoss
//
//  店鋪總覽頁。
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var vm: GameViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    storeHeaderCard
                    quickActionsCard
                    coreStatsGrid
                    progressStatsCard
                    operationsCard
                    recentEventsCard
                }
                .padding()
            }
            .navigationTitle("總覽")
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }

    // MARK: - 店鋪標頭

    private var storeHeaderCard: some View {
        SectionCard(title: vm.store.storeName, icon: "storefront") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("等級 \(vm.store.level)", systemImage: "rosette")
                        .font(.subheadline).foregroundColor(.purple)
                    Spacer()
                    Label("第 \(vm.store.day) 天", systemImage: "calendar")
                        .font(.subheadline).foregroundColor(.blue)
                    Text(String(format: "%02d:00", vm.store.hour))
                        .font(.system(.subheadline, design: .monospaced)).foregroundColor(.secondary)
                }
                HStack {
                    Label(vm.store.isOpen ? "營業中" : "已暫停",
                          systemImage: vm.store.isOpen ? "checkmark.circle.fill" : "pause.circle")
                        .foregroundColor(vm.store.isOpen ? .green : .orange)
                        .font(.subheadline)
                    Spacer()
                    Label(vm.store.isCheatSave ? "外掛存檔" : "正常存檔",
                          systemImage: vm.store.isCheatSave ? "wand.and.stars" : "checkmark.shield")
                        .font(.caption)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background((vm.store.isCheatSave ? Color.orange : Color.green).opacity(0.15))
                        .foregroundColor(vm.store.isCheatSave ? .orange : .green)
                        .cornerRadius(6)
                }
            }
        }
    }

    // MARK: - 快速操作

    private var quickActionsCard: some View {
        SectionCard(title: "快速操作", icon: "bolt.fill") {
            VStack(spacing: 10) {
                Button {
                    if vm.store.isOpen { vm.pauseBusiness() } else { vm.startBusiness() }
                } label: {
                    Label(vm.store.isOpen ? "暫停營業" : "開始營業",
                          systemImage: vm.store.isOpen ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(vm.store.isOpen ? Color.orange : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                HStack(spacing: 10) {
                    quickBtn("手動結帳", "creditcard.fill") { vm.manualCheckout() }
                    quickBtn("快速補貨", "shippingbox.fill") { vm.quickRestock() }
                }
                if vm.store.settings.debugModeEnabled {
                    quickBtn("觸發測試事件", "ladybug", color: .purple) { vm.triggerTestEvent() }
                }
            }
        }
    }

    private func quickBtn(_ title: String, _ icon: String, color: Color = .blue, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(color.opacity(0.15))
                .foregroundColor(color)
                .cornerRadius(8)
        }
    }

    // MARK: - 核心數值

    private var coreStatsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(title: "現金", value: "$\(vm.store.money)", icon: "dollarsign.circle.fill", color: .green)
            StatCard(title: "今日營業額", value: "$\(vm.store.totalRevenueToday)", icon: "cart.fill", color: .blue)
            StatCard(title: "今日利潤", value: profitText, icon: profitIcon, color: vm.store.totalProfitToday >= 0 ? .green : .red,
                     subtitle: vm.store.totalProfitToday < 0 ? "虧損中" : nil)
            StatCard(title: "今日人事成本", value: "$\(vm.store.salaryCostToday)", icon: "person.2.fill", color: .orange)
            StatCard(title: "今日進貨成本", value: "$\(vm.store.purchaseCostToday)", icon: "truck.box.fill", color: .brown)
            StatCard(title: "店鋪估值", value: "$\(vm.store.storeValue)", icon: "building.2.fill", color: .indigo)
        }
    }

    private var profitText: String {
        let p = vm.store.totalProfitToday
        return p >= 0 ? "+$\(p)" : "-$\(abs(p))"
    }
    private var profitIcon: String {
        vm.store.totalProfitToday >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill"
    }

    // MARK: - 進度統計

    private var progressStatsCard: some View {
        SectionCard(title: "店鋪狀態", icon: "gauge.with.dots.needle.67percent") {
            VStack(spacing: 10) {
                ProgressStatView(title: "店鋪名聲", value: vm.store.reputation, icon: "star.fill")
                ProgressStatView(title: "顧客滿意度", value: vm.store.satisfaction, icon: "smiley.fill")
                ProgressStatView(title: "清潔度", value: vm.store.cleanliness, icon: "sparkles")
            }
        }
    }

    // MARK: - 營運狀況

    private var operationsCard: some View {
        SectionCard(title: "營運狀況", icon: "waveform.path.ecg") {
            VStack(spacing: 8) {
                HStack {
                    statRow("目前客人數", "\(vm.store.currentCustomers)")
                    statRow("等待結帳", "\(vm.store.checkoutQueue)")
                }
                HStack {
                    statRow("缺貨商品", "\(vm.outOfStockCount)")
                    statRow("上班員工", "\(vm.workingEmployeeCount)")
                }
            }
        }
    }

    private func statRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).font(.caption).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.system(.subheadline, design: .rounded).weight(.bold))
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
    }

    // MARK: - 最近事件

    private var recentEventsCard: some View {
        SectionCard(title: "最近事件紀錄", icon: "bell.badge") {
            VStack(alignment: .leading, spacing: 6) {
                if vm.store.eventLog.isEmpty {
                    Text("尚無事件").font(.caption).foregroundColor(.secondary)
                } else {
                    ForEach(vm.store.eventLog.suffix(8).reversed(), id: \.self) { log in
                        Text(log)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }
}

#Preview {
    DashboardView().environmentObject(GameViewModel())
}
