//
//  FinanceRecord.swift
//  ConvenienceStoreBoss
//
//  每日財務紀錄。
//

import Foundation

struct FinanceRecord: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var day: Int
    var revenue: Int
    var purchaseCost: Int
    var salaryCost: Int
    var repairCost: Int
    var productLoss: Int
    var profit: Int { revenue - purchaseCost - salaryCost - repairCost - productLoss }
}
