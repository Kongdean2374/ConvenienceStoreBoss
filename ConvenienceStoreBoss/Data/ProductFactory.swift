//
//  ProductFactory.swift
//  ConvenienceStoreBoss
//
//  內建 84 種商品的工廠。
//

import Foundation

enum ProductFactory {

    /// 建立初始商品清單（依需求清單順序）。
    /// 所有商品的容量、價格、需求度都已設定，但初始庫存為 0，玩家需自行進貨。
    static func makeAll() -> [Product] {
        // 預設建議售價 = 進價 * 1.6（無條件進位）
        func p(_ name: String,
               _ category: ProductCategory,
               _ buy: Int,
               _ demand: Int,
               _ shelfLifeDays: Int,
               _ shelfType: ShelfType,
               unlockedLevel: Int = 1,
               capacity: Int = 20,
               cold: Bool = false,
               frozen: Bool = false,
               hot: Bool = false,
               priceScale: Double = 1.0) -> Product {
            let sell = max(1, Int(Double(buy) * 1.6 * priceScale))
            return Product(
                name: name,
                category: category,
                buyPrice: buy,
                sellPrice: sell,
                baseDemand: demand,
                warehouseStock: 0,
                shelfStock: 0,
                shelfCapacity: capacity,
                shelfType: shelfType,
                shelfLifeDays: shelfLifeDays,
                freshness: 100,
                requiresColdStorage: cold,
                requiresFrozen: frozen,
                requiresHotZone: hot,
                unlockedLevel: unlockedLevel,
                isUnlocked: unlockedLevel <= 1
            )
        }

        var list: [Product] = []

        // ===== 食品類（一般貨架 / 冷藏）=====
        list.append(p("御飯糰", .food, 15, 70, 2, .chilled, cold: true))
        list.append(p("鮪魚飯糰", .food, 18, 65, 2, .chilled, cold: true))
        list.append(p("肉鬆飯糰", .food, 18, 60, 2, .chilled, cold: true))
        list.append(p("雞肉飯糰", .food, 20, 68, 2, .chilled, cold: true))
        list.append(p("茶葉蛋", .food, 8, 75, 1, .hotFood, hot: true))
        list.append(p("熱狗", .food, 12, 60, 1, .hotFood, hot: true))
        list.append(p("便當", .food, 45, 80, 1, .chilled, cold: true, capacity: 15))
        list.append(p("雞胸肉", .food, 40, 55, 3, .chilled, cold: true))
        list.append(p("三明治", .food, 25, 65, 2, .chilled, cold: true))
        list.append(p("麵包", .food, 20, 60, 3, .normal))
        list.append(p("沙拉", .food, 35, 50, 2, .chilled, cold: true))
        list.append(p("涼麵", .food, 30, 65, 1, .chilled, cold: true))
        list.append(p("壽司盒", .food, 50, 70, 1, .chilled, cold: true, capacity: 12))
        list.append(p("漢堡", .food, 30, 70, 1, .hotFood, hot: true))
        list.append(p("蛋餅", .food, 22, 65, 1, .hotFood, hot: true))
        list.append(p("飯糰組合餐", .food, 55, 60, 1, .chilled, cold: true, unlockedLevel: 2, capacity: 10))

        // ===== 飲料類 =====
        list.append(p("礦泉水", .drink, 8, 80, 365, .normal, capacity: 30))
        list.append(p("無糖綠茶", .drink, 12, 70, 180, .normal))
        list.append(p("烏龍茶", .drink, 13, 65, 180, .normal))
        list.append(p("奶茶", .drink, 15, 72, 180, .normal))
        list.append(p("黑咖啡", .drink, 18, 75, 180, .normal))
        list.append(p("拿鐵", .drink, 25, 78, 180, .chilled, cold: true))
        list.append(p("氣泡飲", .drink, 14, 60, 365, .normal))
        list.append(p("可樂", .drink, 12, 68, 365, .normal))
        list.append(p("運動飲料", .drink, 16, 65, 365, .normal))
        list.append(p("能量飲", .drink, 25, 75, 365, .normal))
        list.append(p("果汁", .drink, 18, 55, 30, .chilled, cold: true))
        list.append(p("豆漿", .drink, 12, 70, 14, .chilled, cold: true))
        list.append(p("鮮奶", .drink, 25, 60, 7, .chilled, cold: true))
        list.append(p("優酪乳", .drink, 22, 50, 10, .chilled, cold: true))
        list.append(p("檸檬茶", .drink, 15, 62, 180, .normal))
        list.append(p("冰美式", .drink, 30, 70, 1, .chilled, cold: true, unlockedLevel: 2))

        // ===== 零食類 =====
        list.append(p("洋芋片", .snack, 18, 70, 180, .normal))
        list.append(p("巧克力", .snack, 20, 68, 240, .normal))
        list.append(p("餅乾", .snack, 15, 65, 240, .normal))
        list.append(p("口香糖", .snack, 10, 50, 365, .counter))
        list.append(p("布丁", .snack, 18, 55, 14, .chilled, cold: true))
        list.append(p("果凍", .snack, 12, 48, 180, .normal))
        list.append(p("泡芙", .snack, 22, 52, 14, .chilled, cold: true))
        list.append(p("堅果", .snack, 35, 60, 240, .normal))
        list.append(p("魷魚絲", .snack, 30, 55, 180, .normal))
        list.append(p("糖果", .snack, 8, 50, 365, .counter))
        list.append(p("米果", .snack, 20, 60, 240, .normal))
        list.append(p("辣條", .snack, 12, 58, 180, .normal))
        list.append(p("蛋捲", .snack, 35, 55, 180, .normal))
        list.append(p("爆米花", .snack, 18, 50, 180, .normal))
        list.append(p("仙貝", .snack, 16, 52, 240, .normal))
        list.append(p("棉花糖", .snack, 12, 45, 365, .counter))

        // ===== 生活用品類 =====
        list.append(p("衛生紙", .dailyNecessity, 45, 55, 3650, .normal, capacity: 15))
        list.append(p("濕紙巾", .dailyNecessity, 15, 50, 730, .normal))
        list.append(p("牙刷", .dailyNecessity, 20, 40, 1825, .normal))
        list.append(p("牙膏", .dailyNecessity, 30, 45, 1095, .normal))
        list.append(p("洗髮精", .dailyNecessity, 60, 40, 1095, .normal, unlockedLevel: 2))
        list.append(p("沐浴乳", .dailyNecessity, 60, 42, 1095, .normal, unlockedLevel: 2))
        list.append(p("電池", .dailyNecessity, 35, 55, 1825, .counter))
        list.append(p("雨傘", .dailyNecessity, 120, 40, 3650, .counter, capacity: 8))
        list.append(p("口罩", .dailyNecessity, 25, 65, 1095, .counter))
        list.append(p("充電線", .dailyNecessity, 80, 60, 1825, .counter, unlockedLevel: 2, capacity: 10))
        list.append(p("行動電源", .dailyNecessity, 250, 55, 1825, .counter, unlockedLevel: 3, capacity: 6))
        list.append(p("打火機", .dailyNecessity, 10, 45, 3650, .counter))
        list.append(p("刮鬍刀", .dailyNecessity, 90, 35, 1825, .normal, unlockedLevel: 3))
        list.append(p("OK繃", .dailyNecessity, 15, 45, 1095, .counter))
        list.append(p("暖暖包", .dailyNecessity, 12, 60, 365, .counter))
        list.append(p("洗衣精", .dailyNecessity, 70, 40, 1095, .normal, unlockedLevel: 2))

        // ===== 熱食類 =====
        list.append(p("關東煮", .hotFood, 18, 70, 1, .hotFood, hot: true))
        list.append(p("烤地瓜", .hotFood, 25, 60, 3, .hotFood, hot: true))
        list.append(p("炸雞", .hotFood, 45, 75, 1, .hotFood, hot: true))
        list.append(p("薯條", .hotFood, 25, 70, 1, .hotFood, hot: true))
        list.append(p("咖哩飯", .hotFood, 55, 65, 1, .hotFood, hot: true, unlockedLevel: 2))
        list.append(p("熱湯", .hotFood, 30, 55, 1, .hotFood, hot: true))
        list.append(p("包子", .hotFood, 15, 65, 1, .hotFood, hot: true))
        list.append(p("蒸蛋", .hotFood, 18, 50, 1, .hotFood, hot: true))

        // ===== 冷凍類 =====
        list.append(p("冰淇淋", .frozen, 25, 75, 180, .frozen, frozen: true))
        list.append(p("冷凍水餃", .frozen, 50, 65, 180, .frozen, frozen: true))
        list.append(p("冷凍炒飯", .frozen, 45, 60, 180, .frozen, frozen: true))
        list.append(p("冰棒", .frozen, 15, 70, 180, .frozen, frozen: true))
        list.append(p("冷凍披薩", .frozen, 90, 55, 180, .frozen, frozen: true, unlockedLevel: 2))
        list.append(p("冷凍雞塊", .frozen, 60, 60, 180, .frozen, frozen: true))

        // ===== 服務商品（不會過期，櫃檯區）=====
        list.append(p("影印服務", .service, 3, 40, 0, .counter, capacity: 999, priceScale: 5))
        list.append(p("包裹寄送", .service, 30, 35, 0, .counter, capacity: 999, priceScale: 2))
        list.append(p("手機儲值", .service, 100, 50, 0, .counter, capacity: 999, priceScale: 1.1))
        list.append(p("遊戲點數", .service, 100, 55, 0, .counter, capacity: 999, priceScale: 1.1))
        list.append(p("票券代售", .service, 150, 30, 0, .counter, capacity: 999, priceScale: 1.1))
        list.append(p("咖啡寄杯", .service, 60, 45, 0, .counter, capacity: 999, priceScale: 1.5))

        // 服務類商品特殊處理：不會過期、庫存無上限（永遠有貨）
        for i in list.indices where list[i].category == .service {
            list[i].warehouseStock = 999
            list[i].shelfStock = list[i].shelfCapacity
            list[i].isUnlocked = list[i].unlockedLevel <= 1
        }

        return list
    }
}
