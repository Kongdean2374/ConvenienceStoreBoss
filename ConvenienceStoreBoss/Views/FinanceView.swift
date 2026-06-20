//
//  FinanceView.swift
//  ConvenienceStoreBoss
//
//  財務頁：顯示今日 / 昨日 / 歷史財務。
//

import SwiftUI

struct FinanceView: View {
    @EnvironmentObject var vm: GameViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    todayCard
                    historyCard
                    breakdownCard
                    historyListCard
                }
                .padding()
            }
            .navigationTitle("財務報表")
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }

    private var todayCard: some View {
        SectionCard(title: "今日財務", icon: "calendar.day") {
            VStack(spacing: 10) {
                bigStat("今日營業額", "$\(vm.store.totalRevenueToday)", .blue)
                Divider()
                HStack(spacing: 8) {
                    statBox("今日利潤", profitText, vm.store.totalProfitToday >= 0 ? .green : .red)
                    statBox("昨日營業額", "$\(vm.store.yesterdayRevenue)", .gray)
                }
            }
        }
    }

    private var profitText: String {
        let p = vm.store.totalProfitToday
        return p >= 0 ? "+$\(p)" : "-$\(abs(p))"
    }

    private var breakdownCard: some View {
        SectionCard(title: "今日成本明細", icon: "list.bullet.rectangle") {
            VStack(spacing: 8) {
                costRow("進貨成本", vm.store.purchaseCostToday, .brown)
                costRow("人事成本", vm.store.salaryCostToday, .orange)
                costRow("維修成本", vm.store.repairCostToday, .red)
                costRow("商品損失", vm.store.productLossToday, .pink)
            }
        }
    }

    private var historyCard: some View {
        SectionCard(title: "歷史紀錄", icon: "chart.bar.xaxis") {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    statBox("歷史最高日營業額", "$\(vm.store.highestDailyRevenue)", .green)
                    statBox("總賺取金額", "$\(vm.store.totalEarned)", .indigo)
                }
                statBox("店鋪估值", "$\(vm.store.storeValue)", .purple)
            }
        }
    }

    private var historyListCard: some View {
        SectionCard(title: "近期每日紀錄", icon: "clock.arrow.circlepath") {
            VStack(spacing: 6) {
                if vm.store.financeHistory.isEmpty {
                    Text("尚無歷史紀錄").font(.caption).foregroundColor(.secondary)
                } else {
                    ForEach(vm.store.financeHistory.suffix(10).reversed()) { record in
                        HStack {
                            Text("第 \(record.day) 天").font(.caption)
                            Spacer()
                            Text("營收 $\(record.revenue)").font(.caption).foregroundColor(.blue)
                            Text("利潤 \(record.profit >= 0 ? "+$" : "-$")\(abs(record.profit))")
                                .font(.caption).foregroundColor(record.profit >= 0 ? .green : .red)
                        }
                        .padding(.vertical, 4)
                        Divider()
                    }
                }
            }
        }
    }

    private func bigStat(_ title: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(title).font(.subheadline).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.system(.title2, design: .rounded).weight(.bold)).foregroundColor(color)
        }
    }

    private func statBox(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title).font(.caption2).foregroundColor(.secondary).multilineTextAlignment(.center)
            Text(value).font(.system(.headline, design: .rounded).weight(.bold)).foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
    }

    private func costRow(_ title: String, _ value: Int, _ color: Color) -> some View {
        HStack {
            Label(title, systemImage: "minus.circle.fill").foregroundColor(color).font(.subheadline)
            Spacer()
            Text("$\(value)").font(.system(.subheadline, design: .rounded)).foregroundColor(.red)
        }
    }
}

#Preview {
    FinanceView().environmentObject(GameViewModel())
}
