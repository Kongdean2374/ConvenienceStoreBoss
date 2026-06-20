//
//  Product.swift
//  ConvenienceStoreBoss
//
//  單一商品資料模型。
//

import Foundation

struct Product: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var category: ProductCategory
    /// 進貨價（>=0）。
    var buyPrice: Int
    /// 售價（>=1）。
    var sellPrice: Int
    /// 基礎需求度（0~100），越高越容易被買走。
    var baseDemand: Int
    /// 倉庫庫存（>=0）。
    var warehouseStock: Int
    /// 架上庫存（0...shelfCapacity）。
    var shelfStock: Int
    /// 架上容量上限（>=0）。
    var shelfCapacity: Int
    /// 對應貨架類型。
    var shelfType: ShelfType
    /// 保存期限（天數，0 表示服務類商品不會過期）。
    var shelfLifeDays: Int
    /// 新鮮度（0~100），低於 20 觸發客訴。
    var freshness: Int
    /// 是否需要冷藏。
    var requiresColdStorage: Bool
    /// 是否需要冷凍。
    var requiresFrozen: Bool
    /// 是否需要熱食區。
    var requiresHotZone: Bool
    /// 解鎖等級。
    var unlockedLevel: Int
    /// 是否已解鎖（玩家可進貨 / 上架）。
    var isUnlocked: Bool
    /// 是否正在販售（玩家可隨時切換）。
    var isOnSale: Bool
    /// 是否啟用自動補貨。
    var autoRestockEnabled: Bool
    /// 自動補貨警戒線：架上低於此值就觸發。
    var autoRestockThreshold: Int
    /// 自動補貨一次補多少。
    var autoRestockAmount: Int
    /// 今日已售出數量（>=0）。
    var soldToday: Int

    init(
        id: UUID = UUID(),
        name: String,
        category: ProductCategory,
        buyPrice: Int,
        sellPrice: Int,
        baseDemand: Int,
        warehouseStock: Int = 0,
        shelfStock: Int = 0,
        shelfCapacity: Int = 20,
        shelfType: ShelfType,
        shelfLifeDays: Int,
        freshness: Int = 100,
        requiresColdStorage: Bool = false,
        requiresFrozen: Bool = false,
        requiresHotZone: Bool = false,
        unlockedLevel: Int = 1,
        isUnlocked: Bool = true,
        isOnSale: Bool = true,
        autoRestockEnabled: Bool = false,
        autoRestockThreshold: Int = 5,
        autoRestockAmount: Int = 10,
        soldToday: Int = 0
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.buyPrice = max(0, buyPrice)
        self.sellPrice = max(1, sellPrice)
        self.baseDemand = clamp(baseDemand, 0, 100)
        self.warehouseStock = max(0, warehouseStock)
        self.shelfCapacity = max(0, shelfCapacity)
        self.shelfStock = min(max(0, shelfStock), self.shelfCapacity)
        self.shelfType = shelfType
        self.shelfLifeDays = max(0, shelfLifeDays)
        self.freshness = clamp(freshness, 0, 100)
        self.requiresColdStorage = requiresColdStorage
        self.requiresFrozen = requiresFrozen
        self.requiresHotZone = requiresHotZone
        self.unlockedLevel = max(1, unlockedLevel)
        self.isUnlocked = isUnlocked
        self.isOnSale = isOnSale
        self.autoRestockEnabled = autoRestockEnabled
        self.autoRestockThreshold = max(0, autoRestockThreshold)
        self.autoRestockAmount = max(0, autoRestockAmount)
        self.soldToday = max(0, soldToday)
    }
}

/// 限制 value 在 0...upper（含）之間。
@inlinable
func clamp(_ value: Int, _ lower: Int, _ upper: Int) -> Int {
    min(max(value, lower), upper)
}

extension Product {
    /// 利潤率（0~1）。
    var profitMargin: Double {
        guard sellPrice > 0 else { return 0 }
        return Double(sellPrice - buyPrice) / Double(sellPrice)
    }

    /// 是否為服務類商品（不會過期、不需貨架容量）。
    var isService: Bool { category == .service }
}
