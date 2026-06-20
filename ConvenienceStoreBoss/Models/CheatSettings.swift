//
//  CheatSettings.swift
//  ConvenienceStoreBoss
//
//  外掛設定。開啟任一外掛即會將存檔標記為外掛存檔。
//

import Foundation

struct CheatSettings: Codable, Hashable {
    var cheatModeEnabled: Bool = false
    var infiniteMoney: Bool = false
    var allProductsUnlocked: Bool = false
    var allEmployeesUnlocked: Bool = false
    var productsNeverExpire: Bool = false
    var employeesNeverQuit: Bool = false
    var employeesAlwaysHappy: Bool = false
    var customersAlwaysSatisfied: Bool = false
    var eventsAlwaysSuccess: Bool = false
    var maxReputationLocked: Bool = false
    var autoFillWarehouse: Bool = false
    var autoFillShelves: Bool = false
    /// 金錢倍率（>=1）。
    var moneyMultiplier: Double = 1.0
    /// 客流量倍率（>=1）。
    var customerMultiplier: Double = 1.0

    static let `default` = CheatSettings()

    /// 只要任何一項作弊被開啟，就回傳 true。
    var anyCheatActive: Bool {
        infiniteMoney || allProductsUnlocked || allEmployeesUnlocked ||
        productsNeverExpire || employeesNeverQuit || employeesAlwaysHappy ||
        customersAlwaysSatisfied || eventsAlwaysSuccess || maxReputationLocked ||
        autoFillWarehouse || autoFillShelves || moneyMultiplier > 1.0 || customerMultiplier > 1.0
    }
}
