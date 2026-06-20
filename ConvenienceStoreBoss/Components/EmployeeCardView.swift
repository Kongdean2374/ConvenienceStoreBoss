//
//  EmployeeCardView.swift
//  ConvenienceStoreBoss
//
//  單一員工卡片。顯示完整狀態並提供雇用 / 解雇 / 薪資 / 獎金 / 扣薪 / 訓練 / 排班操作。
//

import SwiftUI

struct EmployeeCardView: View {
    let employee: Employee
    @ObservedObject var vm: GameViewModel
    @State private var wageInput: String = ""
    @State private var bonusInput: String = ""
    @State private var trainCostInput: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ===== 標頭 =====
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(employee.name).font(.headline)
                        Text(employee.role.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(roleColor.opacity(0.2))
                            .foregroundColor(roleColor)
                            .cornerRadius(4)
                    }
                    HStack(spacing: 8) {
                        Text("時薪 $\(employee.hourlyWage)").font(.caption).foregroundColor(.green)
                        Text("期望 $\(employee.expectedWage)").font(.caption).foregroundColor(.secondary)
                        if employee.hourlyWage < employee.expectedWage {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange).font(.caption)
                        }
                    }
                }
                Spacer()
                if employee.hired {
                    Text("已雇用")
                        .font(.caption2)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(6)
                } else {
                    Text("待雇用")
                        .font(.caption2)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.gray)
                        .cornerRadius(6)
                }
            }

            // ===== 技能區 =====
            VStack(spacing: 8) {
                skillBar("收銀", employee.cashierSkill)
                skillBar("補貨", employee.restockSkill)
                skillBar("清潔", employee.cleaningSkill)
                skillBar("服務", employee.serviceSkill)
            }

            // ===== 狀態區（雇用後才顯示）=====
            if employee.hired {
                VStack(spacing: 8) {
                    ProgressStatView(title: "心情", value: employee.mood, icon: "face.smiling")
                    ProgressStatView(title: "疲勞", value: employee.fatigue, icon: "tortoise")
                    ProgressStatView(title: "忠誠", value: employee.loyalty, icon: "heart")
                    ProgressStatView(title: "效率", value: employee.efficiency, icon: "bolt")
                    ProgressStatView(title: "離職風險", value: employee.quitRisk, icon: "exclamationmark.triangle", color: employee.quitRisk > 60 ? .red : .blue)
                    ProgressStatView(title: "偷懶風險", value: employee.lazyRisk, icon: "zzz", color: employee.lazyRisk > 60 ? .red : .blue)
                }

                // ===== 排班區 =====
                VStack(alignment: .leading, spacing: 6) {
                    Text("排班").font(.caption).foregroundColor(.secondary)
                    HStack {
                        ForEach(ShiftType.allCases) { shift in
                            Button(shift.rawValue) {
                                if employee.assignedShift == shift {
                                    vm.assignShift(employeeID: employee.id, shift: nil)
                                } else {
                                    vm.assignShift(employeeID: employee.id, shift: shift)
                                }
                            }
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(employee.assignedShift == shift ? Color.blue : Color.gray.opacity(0.15))
                            .foregroundColor(employee.assignedShift == shift ? .white : .primary)
                            .cornerRadius(6)
                        }
                    }
                }

                // ===== 薪資調整 =====
                VStack(alignment: .leading, spacing: 6) {
                    Text("薪資調整").font(.caption).foregroundColor(.secondary)
                    HStack {
                        TextField("時薪", text: $wageInput)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 90)
                        Button("設定") {
                            if let v = Int(wageInput), v >= 0 {
                                _ = vm.setWage(employeeID: employee.id, wage: v)
                                wageInput = ""
                            }
                        }
                        .font(.caption)
                        .padding(.horizontal, 8).padding(.vertical, 6)
                        .background(Color.blue.opacity(0.15)).cornerRadius(6)
                        Spacer()
                        Button("扣 $20") { _ = vm.cutPay(employeeID: employee.id, amount: 20) }
                            .font(.caption)
                            .padding(.horizontal, 8).padding(.vertical, 6)
                            .background(Color.red.opacity(0.15))
                            .foregroundColor(.red)
                            .cornerRadius(6)
                    }
                }

                // ===== 獎金 / 訓練 =====
                VStack(alignment: .leading, spacing: 6) {
                    Text("獎金 / 訓練").font(.caption).foregroundColor(.secondary)
                    HStack(spacing: 8) {
                        TextField("金額", text: $bonusInput)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 70)
                        Button("發獎金") {
                            if let v = Int(bonusInput), v > 0 { _ = vm.giveBonus(employeeID: employee.id, amount: v); bonusInput = "" }
                        }
                        .font(.caption)
                        .padding(.horizontal, 8).padding(.vertical, 6)
                        .background(Color.green.opacity(0.15))
                        .foregroundColor(.green)
                        .cornerRadius(6)
                        TextField("費用", text: $trainCostInput)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 70)
                        Button("訓練") {
                            if let v = Int(trainCostInput), v > 0 { _ = vm.train(employeeID: employee.id, cost: v); trainCostInput = "" }
                        }
                        .font(.caption)
                        .padding(.horizontal, 8).padding(.vertical, 6)
                        .background(Color.purple.opacity(0.15))
                        .foregroundColor(.purple)
                        .cornerRadius(6)
                    }
                }

                // ===== 解雇按鈕 =====
                Button(role: .destructive) {
                    _ = vm.fire(employeeID: employee.id)
                } label: {
                    Label("解雇", systemImage: "person.fill.xmark")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
            } else {
                // ===== 雇用按鈕 =====
                Button {
                    _ = vm.hire(employeeID: employee.id)
                } label: {
                    Label("雇用", systemImage: "person.fill.checkmark")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Subviews

    private func skillBar(_ title: String, _ value: Int) -> some View {
        HStack(spacing: 8) {
            Text(title).font(.caption2).foregroundColor(.secondary).frame(width: 30, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.tertiarySystemFill)).frame(height: 6)
                    Capsule().fill(Color.blue).frame(width: geo.size.width * CGFloat(value) / 100.0, height: 6)
                }
            }
            .frame(height: 6)
            Text("\(value)").font(.caption2).fontWeight(.bold).frame(width: 28, alignment: .trailing)
        }
    }

    private var roleColor: Color {
        switch employee.role {
        case .cashier: return .blue
        case .restocker: return .orange
        case .cleaner: return .teal
        case .manager: return .purple
        }
    }
}
