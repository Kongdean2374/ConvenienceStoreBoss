//
//  Enums.swift
//  ConvenienceStoreBoss
//
//  集中定義所有共用列舉型別。
//

import Foundation

/// 商品分類。
enum ProductCategory: String, Codable, CaseIterable, Identifiable {
    case food          = "食品"
    case drink         = "飲料"
    case snack         = "零食"
    case dailyNecessity = "生活用品"
    case hotFood       = "熱食"
    case chilled       = "冷藏"
    case frozen        = "冷凍"
    case service       = "服務商品"

    var id: String { rawValue }
}

/// 貨架類型。
enum ShelfType: String, Codable, CaseIterable, Identifiable {
    case normal   = "一般貨架"
    case chilled  = "冷藏櫃"
    case frozen   = "冷凍櫃"
    case hotFood  = "熱食區"
    case counter  = "櫃檯區"

    var id: String { rawValue }
}

/// 員工職位。
enum EmployeeRole: String, Codable, CaseIterable, Identifiable {
    case cashier   = "收銀員"
    case restocker = "補貨員"
    case cleaner   = "清潔員"
    case manager   = "值班店長"

    var id: String { rawValue }
}

/// 班別。
enum ShiftType: String, Codable, CaseIterable, Identifiable {
    case morning   = "早班"   // 06:00 - 14:00
    case afternoon = "中班"   // 14:00 - 22:00
    case night     = "夜班"   // 22:00 - 06:00

    var id: String { rawValue }

    /// 該班別對應的遊戲內小時範圍（24h 制）。
    var hourRange: ClosedRange<Int> {
        switch self {
        case .morning:   return 6 ... 13
        case .afternoon: return 14 ... 21
        case .night:     return 22 ... 5   // 注意：跨越午夜
        }
    }
}

/// 事件頻率。
enum EventFrequency: String, Codable, CaseIterable, Identifiable {
    case low      = "低"
    case normal   = "普通"
    case high     = "高"
    case chaos    = "混亂"

    var id: String { rawValue }

    /// 每小時觸發事件的基礎機率（0~1）。
    var triggerChance: Double {
        switch self {
        case .low:    return 0.05
        case .normal: return 0.12
        case .high:   return 0.22
        case .chaos:  return 0.40
        }
    }
}

/// 難度。
enum Difficulty: String, Codable, CaseIterable, Identifiable {
    case casual   = "休閒"
    case standard = "標準"
    case hard     = "困難"
    case hell     = "地獄"

    var id: String { rawValue }

    /// 難度乘數：影響進貨成本、人事成本、事件損失。
    var costMultiplier: Double {
        switch self {
        case .casual:   return 0.8
        case .standard: return 1.0
        case .hard:     return 1.3
        case .hell:     return 1.7
        }
    }

    /// 客流基礎乘數：難度越高客人越少。
    var customerMultiplier: Double {
        switch self {
        case .casual:   return 1.2
        case .standard: return 1.0
        case .hard:     return 0.8
        case .hell:     return 0.6
        }
    }
}

/// 突發事件類型。
enum EventType: String, Codable, CaseIterable, Identifiable {
    case customerTrouble    = "客人鬧事"
    case productExpired     = "商品過期"
    case employeeWageComplaint = "員工抱怨薪水"
    case employeeLate       = "員工遲到"
    case fridgeBroken       = "冷藏櫃故障"
    case hotItemShortage    = "熱門商品缺貨"
    case inspectorRaid      = "稽查員突襲"
    case competitorOpening  = "附近競爭店開幕"
    case midnightRush       = "半夜客流暴增"
    case registerBroken     = "收銀機故障"
    case employeeResign     = "員工想離職"
    case customerLostItem   = "客人遺失物品"

    var id: String { rawValue }
}

/// 升級類型。
enum UpgradeType: String, Codable, CaseIterable, Identifiable {
    case normalShelf   = "一般貨架"
    case fridge        = "冷藏櫃"
    case freezer       = "冷凍櫃"
    case hotZone       = "熱食區"
    case register      = "收銀機"
    case warehouse     = "倉庫容量"
    case cleaningGear  = "清潔設備"
    case camera        = "監視器"
    case breakRoom     = "員工休息室"
    case decoration    = "店面裝潢"

    var id: String { rawValue }
}
