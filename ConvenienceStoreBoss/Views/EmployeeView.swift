//
//  EmployeeView.swift
//  ConvenienceStoreBoss
//
//  員工頁：顯示已雇用 / 待雇用，並提供完整管理。
//

import SwiftUI

struct EmployeeView: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var filter: Filter = .all

    enum Filter: String, CaseIterable, Identifiable {
        case all = "全部"
        case hired = "已雇用"
        case available = "待雇用"
        var id: String { rawValue }
    }

    var filteredEmployees: [Employee] {
        vm.store.employees.filter { e in
            switch filter {
            case .all: return true
            case .hired: return e.hired
            case .available: return !e.hired
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    summaryCard
                    filterPicker
                    employeeList
                }
                .padding()
            }
            .navigationTitle("員工管理")
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }

    private var summaryCard: some View {
        SectionCard(title: "人力總覽", icon: "person.3.fill") {
            HStack(spacing: 8) {
                summaryItem("已雇用", "\(vm.store.employees.filter { $0.hired }.count)", .green)
                summaryItem("待雇用", "\(vm.store.employees.filter { !$0.hired }.count)", .blue)
                summaryItem("在班中", "\(vm.workingEmployeeCount)", .orange)
            }
        }
    }

    private func summaryItem(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(.title3, design: .rounded).weight(.bold)).foregroundColor(color)
            Text(title).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }

    private var filterPicker: some View {
        Picker("篩選", selection: $filter) {
            ForEach(Filter.allCases) { f in Text(f.rawValue).tag(f) }
        }
        .pickerStyle(.segmented)
    }

    private var employeeList: some View {
        LazyVStack(spacing: 12) {
            ForEach(filteredEmployees) { employee in
                EmployeeCardView(employee: employee, vm: vm)
            }
        }
    }
}

#Preview {
    EmployeeView().environmentObject(GameViewModel())
}
