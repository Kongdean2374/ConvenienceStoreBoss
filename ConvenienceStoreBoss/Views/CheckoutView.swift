//
//  CheckoutView.swift
//  ConvenienceStoreBoss
//
//  收銀頁：顯示排隊人數、收銀速度、手動結帳。
//

import SwiftUI

struct CheckoutView: View {
    @EnvironmentObject var vm: GameViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                queueCard
                cashierCard
                manualCheckoutCard
            }
            .padding()
        }
    }

    private var queueCard: some View {
        SectionCard(title: "結帳排隊", icon: "person.fill.viewfinder") {
            VStack(spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("等待人數").font(.caption).foregroundColor(.secondary)
                        Text("\(vm.store.checkoutQueue)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(vm.store.checkoutQueue > 8 ? .red : .primary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("待結帳金額").font(.caption).foregroundColor(.secondary)
                        Text("$\(vm.store.pendingCheckoutRevenue)")
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundColor(.green)
                    }
                }
                if vm.store.checkoutQueue > 8 {
                    Label("排隊過多，滿意度下降中", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption).foregroundColor(.orange)
                }
            }
        }
    }

    private var cashierCard: some View {
        SectionCard(title: "收銀狀態", icon: "creditcard.fill") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("每小時可處理").font(.subheadline)
                    Spacer()
                    Text("\(vm.checkoutCapacity) 人")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(.blue)
                }
                Divider()
                let shift = currentShiftName
                Text("目前時段：\(shift)").font(.caption).foregroundColor(.secondary)
                let cashiers = workingCashiers
                if cashiers.isEmpty {
                    Label("目前沒有員工在班，請手動結帳", systemImage: "hand.point.up.left.fill")
                        .font(.caption).foregroundColor(.orange)
                } else {
                    Text("在班收銀員：").font(.caption).foregroundColor(.secondary)
                    ForEach(cashiers, id: \.id) { e in
                        Label("\(e.name)（收銀 \(e.cashierSkill) / 效率 \(e.efficiency)）", systemImage: "person.fill.checkmark")
                            .font(.caption).foregroundColor(.green)
                    }
                }
            }
        }
    }

    private var manualCheckoutCard: some View {
        SectionCard(title: "手動結帳", icon: "hand.tap.fill") {
            VStack(spacing: 8) {
                Button {
                    vm.manualCheckout()
                } label: {
                    Label("手動結帳（一次 3 人）", systemImage: "creditcard.and.123")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                Text("提示：有員工在班時會自動結帳。")
                    .font(.caption2).foregroundColor(.secondary)
            }
        }
    }

    private var currentShiftName: String {
        switch vm.store.hour {
        case 6...13: return "早班"
        case 14...21: return "中班"
        default: return "夜班"
        }
    }

    private var workingCashiers: [Employee] {
        let shiftType: ShiftType
        switch vm.store.hour {
        case 6...13: shiftType = .morning
        case 14...21: shiftType = .afternoon
        default: shiftType = .night
        }
        return vm.store.employees.filter { $0.hired && $0.assignedShift == shiftType && ($0.role == .cashier || $0.role == .manager) }
    }
}

#Preview {
    CheckoutView().environmentObject(GameViewModel())
}
