//
//  StoreData.swift
//  ConvenienceStoreBoss
//
//  整個店鋪的存檔資料根模型。
//

import Foundation

struct StoreData: Codable {
    // ===== 基本狀態 =====
    var storeName: String = "我的便利店"
    var money: Int = 5000
    var level: Int = 1
    var reputation: Int = 50        // 0~100
    var satisfaction: Int = 70      // 0~100
    var cleanliness: Int = 80       // 0~100
    var currentCustomers: Int = 0
    var checkoutQueue: Int = 0

    // ===== 今日財務 =====
    var totalRevenueToday: Int = 0
    var totalProfitToday: Int = 0
    var purchaseCostToday: Int = 0
    var salaryCostToday: Int = 0
    var repairCostToday: Int = 0
    var productLossToday: Int = 0

    // ===== 歷史財務 =====
    var yesterdayRevenue: Int = 0
    var highestDailyRevenue: Int = 0
    var totalEarned: Int = 0
    var storeValue: Int = 5000
    var financeHistory: [FinanceRecord] = []

    // ===== 遊戲時間 =====
    var day: Int = 1
    var hour: Int = 8
    var isOpen: Bool = false

    // ===== 標記 =====
    var isCheatSave: Bool = false

    // ===== 內容物 =====
    var products: [Product] = []
    var employees: [Employee] = []
    var shifts: [WorkShift] = [
        WorkShift(type: .morning, employeeIDs: []),
        WorkShift(type: .afternoon, employeeIDs: []),
        WorkShift(type: .night, employeeIDs: [])
    ]
    var upgrades: [Upgrade] = []

    // ===== 設定 =====
    var settings: GameSettings = .default
    var cheats: CheatSettings = .default

    // ===== 訊息 =====
    var eventLog: [String] = []
    var currentEvent: StoreEvent?
    var debugLog: [String] = []

    /// 待結帳金額暫存（客人尚未結帳的累積金額），避免「先扣庫存再加錢」造成金流錯誤。
    var pendingCheckoutRevenue: Int = 0
}
