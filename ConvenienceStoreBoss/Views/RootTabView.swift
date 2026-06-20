//
//  RootTabView.swift
//  ConvenienceStoreBoss
//
//  App 主容器：底部 TabView（總覽/經營/員工/財務/設定），
//  Debug 模式時多一個 Debug Tab。事件彈窗與浮動提示在這裡統一管理。
//

import SwiftUI

struct RootTabView: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var selectedTab: Tab = .dashboard

    enum Tab: Hashable {
        case dashboard, business, employee, finance, settings, debug
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tabItem { Label("總覽", systemImage: "chartbar.doc.horizontal") }
                    .tag(Tab.dashboard)

                BusinessView()
                    .tabItem { Label("經營", systemImage: "cart.fill") }
                    .tag(Tab.business)

                EmployeeView()
                    .tabItem { Label("員工", systemImage: "person.3.fill") }
                    .tag(Tab.employee)

                FinanceView()
                    .tabItem { Label("財務", systemImage: "yensign.circle.fill") }
                    .tag(Tab.finance)

                SettingsView()
                    .tabItem { Label("設定", systemImage: "gearshape.fill") }
                    .tag(Tab.settings)

                if vm.store.settings.debugModeEnabled {
                    DebugView()
                        .tabItem { Label("Debug", systemImage: "ladybug.fill") }
                        .tag(Tab.debug)
                }
            }

            // 浮動提示
            if let toast = vm.toast {
                Text(toast)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(20)
                    .padding(.bottom, 90)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        // 事件彈窗
        .sheet(isPresented: Binding(
            get: { vm.store.currentEvent != nil },
            set: { if !$0 { vm.store.currentEvent = nil } }
        )) {
            if let event = vm.store.currentEvent {
                NavigationStack {
                    EventModalView(event: event)
                        .environmentObject(vm)
                        .interactiveDismissDisabled(true)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: vm.toast)
    }
}

#Preview {
    RootTabView().environmentObject(GameViewModel())
}
