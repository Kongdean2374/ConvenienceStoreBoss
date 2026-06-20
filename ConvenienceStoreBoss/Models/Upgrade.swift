//
//  Upgrade.swift
//  ConvenienceStoreBoss
//
//  店鋪升級項目。
//

import Foundation

struct Upgrade: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var description: String
    /// 目前等級（0 起算）。
    var level: Int
    /// 最大等級。
    var maxLevel: Int
    /// 等級 0 -> 1 的基礎費用。
    var baseCost: Int
    var type: UpgradeType

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        level: Int = 0,
        maxLevel: Int = 5,
        baseCost: Int,
        type: UpgradeType
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.level = max(0, level)
        self.maxLevel = max(1, maxLevel)
        self.baseCost = max(0, baseCost)
        self.type = type
    }

    /// 目前升到下一級的費用（費用隨等級遞增）。已滿級回傳 0。
    var nextCost: Int {
        guard level < maxLevel else { return 0 }
        // 每級費用 = baseCost * (level + 1) * 1.6^level
        let multiplier = pow(1.6, Double(level))
        return Int(Double(baseCost) * Double(level + 1) * multiplier)
    }

    var isMaxed: Bool { level >= maxLevel }
}
