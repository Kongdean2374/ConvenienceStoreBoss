//
//  ConvenienceStoreBossApp.swift
//  ConvenienceStoreBoss
//
//  App 進入點。
//

import SwiftUI

@main
struct ConvenienceStoreBossApp: App {
    // 唯一的遊戲狀態，整個 App 共用。
    @StateObject private var vm = GameViewModel()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(vm)
                .preferredColorScheme(nil)   // 跟隨系統深色模式
        }
    }
}
