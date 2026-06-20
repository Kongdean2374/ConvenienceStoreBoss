//
//  GameSettings.swift
//  ConvenienceStoreBoss
//
//  玩家遊戲設定（不含作弊）。
//

import Foundation

struct GameSettings: Codable, Hashable {
    var soundEnabled: Bool = true
    var hapticEnabled: Bool = true
    var autoSaveEnabled: Bool = true
    /// 遊戲速度倍率。
    var gameSpeed: Double = 1.0
    var eventFrequency: EventFrequency = .normal
    var difficulty: Difficulty = .standard
    var showRestockWarning: Bool = true
    var showSalaryWarning: Bool = true
    var showCustomerComplaintWarning: Bool = true
    var debugModeEnabled: Bool = false

    // ===== 老闆設定 =====
    /// 預設售價倍率（相對於建議售價）。
    var defaultPriceMultiplier: Double = 1.0
    /// 自動補貨警戒線（架上剩餘百分比）。
    var autoRestockThresholdPercent: Int = 25
    /// 自動補貨一次數量。
    var autoRestockAmount: Int = 10
    /// 員工最低薪資提醒（低於此值會提示）。
    var minWageReminder: Int = 150
    /// 是否允許員工自動補貨。
    var allowEmployeeAutoRestock: Bool = true
    /// 是否允許值班店長自動處理小事件。
    var allowManagerAutoHandleEvents: Bool = true

    static let `default` = GameSettings()
}
