//
//  StoreEvent.swift
//  ConvenienceStoreBoss
//
//  突發事件資料模型。
//

import Foundation

/// 事件效果。負值代表扣減、正值代表增加。
struct EventEffect: Codable, Hashable {
    var moneyChange: Int = 0
    var reputationChange: Int = 0
    var satisfactionChange: Int = 0
    var cleanlinessChange: Int = 0
    var employeeMoodChange: Int = 0
    var employeeLoyaltyChange: Int = 0
    /// 員工疲勞變化（選用，半夜事件用）。
    var employeeFatigue: Int = 0
    /// 商品損失（影響所有或指定貨架商品，依套用邏輯而定）。
    var productLoss: Int = 0
    var message: String = ""
}

/// 玩家可選的選項。
struct EventChoice: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    /// 成功機率（0~100）。
    var successChance: Int
    var successEffect: EventEffect
    var failEffect: EventEffect
}

/// 一次突發事件。
struct StoreEvent: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var choices: [EventChoice]
    var eventType: EventType
}
