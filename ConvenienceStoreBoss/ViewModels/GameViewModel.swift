//
//  GameViewModel.swift
//  ConvenienceStoreBoss
//
//  核心說明（非常重要）：
//
//  1. 為什麼所有扣錢都要走 safeSpendMoney？
//     因為任何 -、-= 都可能在資金不足時把 money 扣成負數，
//     導致遊戲邏輯崩潰（負金錢、UI 顯示亂碼、存檔壞掉）。
//     safeSpendMoney 統一做「資金檢查 + 外掛無限錢 + clamp」，確保 money 永不為負。
//
//  2. 為什麼所有庫存異動都要走 safeRemoveWarehouseStock / safeRemoveShelfStock？
//     因為商品售出、補貨、事件損失都會動庫存，若直接 - 可能扣成負數。
//     集中走安全方法可以確保：倉庫不為負、架上不為負、架上不超過容量。
//
//  3. 為什麼存檔前後要 validate？
//     存檔前 clamp：避免把壞資料永久寫進 UserDefaults。
//     讀檔後 clamp：避免舊版存檔、匯入存檔、壞存檔造成遊戲崩潰。
//     validate 是「最後一道防線」，即使前面有 Bug，資料也不會真的壞掉。
//
//  4. DebugView 是用來測試與修復資料，不是正常玩法的一部分。
//     DebugView 的「製造負數測試」是故意製造壞資料來驗證修復能力，
//     只在 settings.debugModeEnabled = true 時顯示，正常玩家看不到。
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class GameViewModel: ObservableObject {

    /// 時間型別別名，提高可讀性。
    private typealias Hour = Int

    // MARK: - Published State

    /// 店鋪完整資料。所有 UI 都觀察這個。
    @Published var store: StoreData

    /// 短暫的浮動提示訊息（例如「資金不足」）。
    @Published var toast: String?

    /// 是否顯示事件彈窗。由 store.currentEvent 驅動。
    var hasActiveEvent: Bool { store.currentEvent != nil }

    // MARK: - Internal

    /// 遊戲 tick 計時器。
    private var tickTimer: Timer?
    /// 距離上次自動存檔的 tick 數，避免每秒狂存。
    private var ticksSinceLastSave: Int = 0
    /// 每 N 個 tick 自動存一次。
    private let autoSaveIntervalTicks = 10
    /// 暫存商品索引，加速查找（key = product id）。
    private var productIndex: [UUID: Int] = [:]

    // MARK: - Init

    init() {
        let loaded = SaveService.loadOrCreate()
        var safe = loaded
        Self.clampInPlace(&safe)
        self.store = safe
        HapticService.enabled = safe.settings.hapticEnabled
        validateAfterLoad()
    }

    private func rebuildProductIndex() {
        productIndex.removeAll(keepingCapacity: true)
        for (i, p) in store.products.enumerated() {
            productIndex[p.id] = i
        }
    }

    // MARK: - Toast Helper

    func showToast(_ message: String) {
        toast = message
        let id = UUID()
        lastToastID = id
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            await MainActor.run {
                if self?.lastToastID == id { self?.toast = nil }
            }
        }
    }
    private var lastToastID: UUID?

    // MARK: - Game Loop

    /// 開始營業。
    func startBusiness() {
        guard !store.isOpen else { return }
        store.isOpen = true
        appendEventLog("第 \(store.day) 天 營業開始。")
        HapticService.light()
        startTimer()
    }

    /// 暫停營業。
    func pauseBusiness() {
        store.isOpen = false
        tickTimer?.invalidate()
        tickTimer = nil
        autosaveNow()
    }

    private func startTimer() {
        tickTimer?.invalidate()
        // 每 1 秒 tick 一次，tick 內依 gameSpeed 推進時間。
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            // Timer 在非 Main Actor 佇列觸發，但搭配 @MainActor 類別，
            // 用 dispatchAsyncOnMain 安全切回主執行緒。
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    /// 一次遊戲 tick。對應需求文件「五、店鋪經營流程」的 15 步。
    func tick() {
        guard store.isOpen else { return }

        // 1. 依遊戲速度推進時間（1 tick = gameSpeed 小時，至少 1 小時）。
        let hoursToAdvance = max(1, Int(store.settings.gameSpeed.rounded()))
        for _ in 0..<hoursToAdvance {
            advanceOneHour()
        }

        // 14. clamp。
        Self.clampInPlace(&store)

        // 15. 自動存檔（節流）。
        ticksSinceLastSave += 1
        if store.settings.autoSaveEnabled && ticksSinceLastSave >= autoSaveIntervalTicks {
            autosaveNow()
            ticksSinceLastSave = 0
        }
    }

    /// 推進一小時。把所有每小時邏輯集中。
    private func advanceOneHour() {
        store.hour += 1
        if store.hour >= 24 {
            store.hour = 0
            endOfDay()
            store.day += 1
        }

        let hour = store.hour

        // 2. 生成客人（依時段、名聲、難度、客流倍率）。
        generateCustomers(hour: hour)

        // 3 + 4. 客人購買（扣除架上庫存，累積待結帳金額到 pendingCheckoutRevenue）。
        processCustomerPurchases(hour: hour)

        // 5. 客人進入收銀排隊。
        // 6 + 7. 結帳處理。
        processCheckout(hour: hour)

        // 9. 排隊太久降低滿意度。
        if store.checkoutQueue > 8 {
            store.satisfaction = clamp(store.satisfaction - 3, 0, 100)
        }
        // 10. 缺貨太多降低滿意度。
        let outOfStockCount = store.products.filter { $0.isOnSale && $0.isUnlocked && $0.shelfStock == 0 && !$0.isService }.count
        if outOfStockCount > 5 {
            store.satisfaction = clamp(store.satisfaction - 2, 0, 100)
        }

        // 11. 清潔度逐漸下降（受清潔設備升級與清潔員影響）。
        let cleaningDrop = computeCleaningDrop()
        store.cleanliness = clamp(store.cleanliness - cleaningDrop, 0, 100)
        // 自動清潔
        autoClean()

        // 12. 員工疲勞上升 / 心情 / 忠誠 / 離職偷懶風險。
        updateEmployees(hour: hour)

        // 商品新鮮度下降（非服務類）。
        decayFreshness()

        // 自動補貨（員工或玩家設定）。
        autoRestock()

        // 13. 機率觸發突發事件。
        tryTriggerEvent()
    }

    // MARK: - Time / Day

    /// 一天結束：結算財務、扣薪水、紀錄歷史。
    private func endOfDay() {
        // 結算今日利潤。
        store.totalProfitToday = store.totalRevenueToday
            - store.purchaseCostToday
            - store.salaryCostToday
            - store.repairCostToday
            - store.productLossToday

        // 歷史最高。
        if store.totalRevenueToday > store.highestDailyRevenue {
            store.highestDailyRevenue = store.totalRevenueToday
        }

        // 寫入歷史紀錄。
        let record = FinanceRecord(
            day: store.day,
            revenue: store.totalRevenueToday,
            purchaseCost: store.purchaseCostToday,
            salaryCost: store.salaryCostToday,
            repairCost: store.repairCostToday,
            productLoss: store.productLossToday
        )
        store.financeHistory.append(record)
        if store.financeHistory.count > 60 { store.financeHistory.removeFirst() }

        // 結算員工薪資：今日所有在班員工的累計薪資已在 salaryCostToday 持續累加，
        // 這裡統一從 money 扣除（走安全扣款）。
        if store.salaryCostToday > 0 {
            let ok = safeSpendMoney(amount: store.salaryCostToday, reason: "第 \(store.day) 天員工薪資")
            if !ok {
                // 資金不足付薪水：不能讓 money 變負，改降員工心情忠誠。
                for i in store.employees.indices where store.employees[i].hired {
                    store.employees[i].mood = clamp(store.employees[i].mood - 10, 0, 100)
                    store.employees[i].loyalty = clamp(store.employees[i].loyalty - 12, 0, 100)
                    store.employees[i].quitRisk = clamp(store.employees[i].quitRisk + 15, 0, 100)
                }
                appendEventLog("⚠️ 資金不足，無法支付第 \(store.day) 天薪資 \(store.salaryCostToday) 元，員工士氣大降。")
                // 薪水沒付，但仍要清零計數器避免重複累積。
                store.salaryCostToday = 0
            } else {
                appendEventLog("已支付第 \(store.day) 天薪資共 \(store.salaryCostToday) 元。")
                store.salaryCostToday = 0
            }
        }

        // 昨日營收。
        store.yesterdayRevenue = store.totalRevenueToday

        // 重置今日計數。
        store.totalRevenueToday = 0
        store.purchaseCostToday = 0
        store.repairCostToday = 0
        store.productLossToday = 0
        store.totalProfitToday = 0
        for i in store.products.indices { store.products[i].soldToday = 0 }

        // 重算店鋪估值。
        recomputeStoreValue()

        appendEventLog("第 \(store.day) 天結束，準備進入第 \(store.day + 1) 天。")
        autosaveNow()
    }

    private func recomputeStoreValue() {
        let inventoryValue = store.products.reduce(0) { $0 + $1.shelfStock * $1.buyPrice + $1.warehouseStock * $1.buyPrice }
        let upgradeValue = store.upgrades.reduce(0) { $0 + $1.level * $1.baseCost }
        store.storeValue = max(0, store.money + inventoryValue + upgradeValue)
    }

    // MARK: - Customers

    private func generateCustomers(hour: Int) {
        // 基礎客流：受時段、名聲、滿意度、難度、客流倍率影響。
        var base = 3
        // 時段加成
        switch hour {
        case 6...9: base += 5    // 早餐
        case 11...13: base += 8  // 午餐
        case 17...21: base += 7  // 晚餐
        case 22...24, 0...5: base += 4 // 夜間
        default: base += 2
        }
        // 名聲 / 滿意度
        base = Int(Double(base) * (0.5 + Double(store.reputation) / 100.0))
        base = Int(Double(base) * (0.6 + Double(store.satisfaction) / 250.0))
        // 難度
        base = Int(Double(base) * store.settings.difficulty.customerMultiplier)
        // 客流倍率（外掛）
        base = Int(Double(base) * store.cheats.customerMultiplier)
        // 裝潢升級加成
        let deco = upgradeLevel(.decoration)
        base += deco * 2

        base = max(0, base)
        store.currentCustomers = clamp(store.currentCustomers + base, 0, 200)
    }

    private func processCustomerPurchases(hour: Int) {
        // 每個客人嘗試買 0~2 樣商品。
        let customers = store.currentCustomers
        var boughtAny = false

        for _ in 0..<customers {
            guard store.currentCustomers > 0 else { break }
            let buyCount = Int.random(in: 0...2)
            for _ in 0..<buyCount {
                guard let candidate = pickProductToBuy(hour: hour) else { continue }
                guard let idx = productIndex[candidate.id] else { continue }
                let product = store.products[idx]

                // 售出前必須先檢查 shelfStock > 0。
                guard product.shelfStock > 0 else { continue }

                // 售價過高會降低購買率。
                let priceRatio = Double(product.sellPrice) / Double(max(1, Int(Double(product.buyPrice) * 1.6)))
                let buyChance = min(0.95, max(0.05, Double(product.baseDemand) / 100.0 / max(1.0, priceRatio)))
                guard Double.random(in: 0...1) < buyChance else { continue }

                // 安全扣除架上庫存。
                guard safeRemoveShelfStock(productID: product.id, amount: 1, logFailure: false) else { continue }

                // 累積金額到 pendingCheckoutRevenue（待結帳）。
                let earned = Int(Double(product.sellPrice) * store.cheats.moneyMultiplier)
                store.pendingCheckoutRevenue += max(0, earned)
                store.products[idx].soldToday += 1
                boughtAny = true
            }
            // 一個客人買完後離開（進入結帳排隊）。
            store.currentCustomers = max(0, store.currentCustomers - 1)
            store.checkoutQueue = clamp(store.checkoutQueue + 1, 0, 100)
        }

        if boughtAny {
            // 排隊過多降低滿意度的細節在 advanceOneHour 處理。
        }
    }

    /// 依時段挑選一件架上商品。
    private func pickProductToBuy(hour: Int) -> Product? {
        let onSale = store.products.filter { $0.isOnSale && $0.isUnlocked && $0.shelfStock > 0 }
        guard !onSale.isEmpty else { return nil }

        // 時段偏好分類。
        let preferred: Set<ProductCategory>
        switch hour {
        case 6...10: preferred = [.food, .drink]       // 早餐：飯糰、咖啡、豆漿
        case 11...14: preferred = [.food, .drink]      // 午餐：便當、涼麵
        case 18...22: preferred = [.snack, .hotFood, .drink] // 晚上
        default: preferred = [.snack, .drink]          // 深夜
        }

        let pool = onSale.filter { preferred.contains($0.category) }
        let finalPool = pool.isEmpty ? onSale : pool
        return finalPool.randomElement()
    }

    // MARK: - Checkout

    private func processCheckout(hour: Hour) {
        // 判斷目前時段是否有在班員工。
        let shift = currentShift(forHour: hour)
        let workingCashiers = workingEmployees(forShift: shift).filter { $0.role == .cashier || $0.role == .manager }

        if !workingCashiers.isEmpty {
            // 有員工：依收銀能力自動結帳。
            let totalSkill = workingCashiers.reduce(0) { $0 + $1.cashierSkill + $1.efficiency / 2 }
            let registerBoost = 1 + upgradeLevel(.register)  // 收銀機升級
            let capacity = max(1, totalSkill / 40 * registerBoost)
            let processed = min(store.checkoutQueue, capacity)
            finishCheckout(count: processed)
        }
        // 沒有員工時：玩家需手動按「手動結帳」（manualCheckout()）。
    }
    /// 完成結帳：把 pendingCheckoutRevenue 入帳，扣排隊人數。
    private func finishCheckout(count: Int) {
        let safeCount = max(0, min(count, store.checkoutQueue))
        guard safeCount > 0 else { return }
        // 平均每位客人貢獻的金額。
        let avg = store.pendingCheckoutRevenue / max(1, store.checkoutQueue)
        let revenue = avg * safeCount
        safeAddMoney(amount: revenue, reason: "結帳收入")
        store.totalRevenueToday += revenue
        store.totalEarned += revenue
        store.pendingCheckoutRevenue = max(0, store.pendingCheckoutRevenue - revenue)
        store.checkoutQueue = max(0, store.checkoutQueue - safeCount)
        // 滿意度小幅上升。
        store.satisfaction = clamp(store.satisfaction + 1, 0, 100)
    }

    /// 玩家手動結帳（沒員工時）。一次處理少量。
    func manualCheckout() {
        guard store.checkoutQueue > 0 else {
            showToast("目前沒有等待結帳的客人")
            return
        }
        let processCount = min(store.checkoutQueue, 3)
        finishCheckout(count: processCount)
        HapticService.light()
    }

    // MARK: - Cleaning

    private func computeCleaningDrop() -> Int {
        var drop = 2
        // 清潔設備升級降低下降速度。
        drop = max(0, drop - upgradeLevel(.cleaningGear))
        return drop
    }

    private func autoClean() {
        let shift = currentShift(forHour: store.hour)
        let cleaners = workingEmployees(forShift: shift).filter { $0.role == .cleaner || $0.role == .manager }
        let gain = cleaners.reduce(0) { $0 + $1.cleaningSkill / 20 } + upgradeLevel(.cleaningGear)
        if gain > 0 {
            store.cleanliness = clamp(store.cleanliness + gain, 0, 100)
        }
    }

    // MARK: - Employees

    private func updateEmployees(hour: Int) {
        let shift = currentShift(forHour: hour)
        for i in store.employees.indices where store.employees[i].hired {
            var e = store.employees[i]
            let working = shift == e.assignedShift
            e.isWorkingNow = working

            if working {
                // 疲勞上升（員工休息室升級降低）。
                let fatigueGain = max(0, 3 - upgradeLevel(.breakRoom))
                e.fatigue = clamp(e.fatigue + fatigueGain, 0, 100)
                // 累計今日薪資。
                let wage = Int(Double(e.hourlyWage) * store.settings.difficulty.costMultiplier)
                store.salaryCostToday += max(0, wage)
            } else {
                // 休息降低疲勞。
                e.fatigue = clamp(e.fatigue - 5, 0, 100)
            }

            // 薪資 vs 期望：影響心情、效率、離職、偷懶。
            if e.hourlyWage >= e.expectedWage {
                e.mood = clamp(e.mood + 1, 0, 100)
                e.efficiency = clamp(e.efficiency + 1, 0, 100)
                e.quitRisk = clamp(e.quitRisk - 1, 0, 100)
                e.lazyRisk = clamp(e.lazyRisk - 1, 0, 100)
            } else {
                let gap = e.expectedWage - e.hourlyWage
                e.mood = clamp(e.mood - max(1, gap / 20), 0, 100)
                e.efficiency = clamp(e.efficiency - 1, 0, 100)
                e.quitRisk = clamp(e.quitRisk + max(1, gap / 30), 0, 100)
                e.lazyRisk = clamp(e.lazyRisk + max(1, gap / 40), 0, 100)
            }

            // 疲勞過高進一步惡化。
            if e.fatigue > 70 {
                e.efficiency = clamp(e.efficiency - 2, 0, 100)
                e.quitRisk = clamp(e.quitRisk + 2, 0, 100)
            }

            // 外掛：員工永遠滿意 / 永不離職。
            if store.cheats.employeesAlwaysHappy {
                e.mood = 100
                e.fatigue = 0
            }
            if store.cheats.employeesNeverQuit {
                e.quitRisk = 0
            }

            // 真正離職判定（每小時低機率）。
            if !store.cheats.employeesNeverQuit && e.quitRisk > 80 && Int.random(in: 0...100) < 5 {
                e.hired = false
                e.assignedShift = nil
                e.isWorkingNow = false
                appendEventLog("💔 \(e.name) 離職了。")
            }

            store.employees[i] = e
        }

        // 同步班別裡的員工。
        syncShifts()
    }

    private func syncShifts() {
        for si in store.shifts.indices {
            let validIDs = Set(store.employees.filter { $0.hired }.map { $0.id })
            store.shifts[si].employeeIDs = store.shifts[si].employeeIDs.filter { validIDs.contains($0) }
        }
    }

    /// 取得某時段目前實際在班的員工。
    private func workingEmployees(forShift shift: ShiftType) -> [Employee] {
        store.employees.filter { $0.hired && $0.assignedShift == shift }
    }

    private func currentShift(forHour hour: Int) -> ShiftType {
        switch hour {
        case 6...13: return .morning
        case 14...21: return .afternoon
        default: return .night
        }
    }

    // MARK: - Freshness / Auto Restock

    private func decayFreshness() {
        if store.cheats.productsNeverExpire { return }
        for i in store.products.indices where !store.products[i].isService && store.products[i].shelfLifeDays > 0 {
            // 每小時微降，低新鮮度有機率觸發客訴事件。
            store.products[i].freshness = clamp(store.products[i].freshness - 1, 0, 100)
        }
    }

    private func autoRestock() {
        // 外掛自動補滿。
        if store.cheats.autoFillShelves {
            for i in store.products.indices where store.products[i].isUnlocked {
                let cap = store.products[i].shelfCapacity
                if store.products[i].shelfStock < cap {
                    let need = cap - store.products[i].shelfStock
                    let fromWarehouse = min(need, store.products[i].warehouseStock)
                    if fromWarehouse > 0 {
                        _ = safeRemoveWarehouseStock(productID: store.products[i].id, amount: fromWarehouse, logFailure: false)
                        safeAddShelfStock(productID: store.products[i].id, amount: fromWarehouse)
                    }
                }
            }
        }
        if store.cheats.autoFillWarehouse {
            for i in store.products.indices where store.products[i].isUnlocked {
                if store.products[i].warehouseStock < 50 {
                    store.products[i].warehouseStock = 999
                }
            }
        }

        // 玩家設定的商品自動補貨。
        let allowEmployeeAutoRestock = store.settings.allowEmployeeAutoRestock
        let shift = currentShift(forHour: store.hour)
        let hasRestocker = !workingEmployees(forShift: shift).filter { $0.role == .restocker || $0.role == .manager }.isEmpty

        for i in store.products.indices {
            let p = store.products[i]
            guard p.autoRestockEnabled, p.isUnlocked else { continue }
            // 沒有補貨員時，只有玩家允許才能自動補。
            if !allowEmployeeAutoRestock && !hasRestocker { continue }
            if p.shelfStock <= p.autoRestockThreshold {
                let need = min(p.autoRestockAmount, p.shelfCapacity - p.shelfStock)
                let fromWarehouse = min(need, p.warehouseStock)
                if fromWarehouse > 0 {
                    _ = safeRemoveWarehouseStock(productID: p.id, amount: fromWarehouse, logFailure: false)
                    safeAddShelfStock(productID: p.id, amount: fromWarehouse)
                }
            }
        }
    }

    // MARK: - Events

    private func tryTriggerEvent() {
        // 已有事件待處理就不觸發新的。
        if store.currentEvent != nil { return }
        let chance = store.settings.eventFrequency.triggerChance
        // 監視器降低負面事件。
        let cameraReduce = Double(upgradeLevel(.camera)) * 0.02
        let finalChance = max(0, chance - cameraReduce)
        if Double.random(in: 0...1) < finalChance {
            store.currentEvent = EventFactory.randomEvent()
        }
    }

    /// 玩家選了某個事件選項。
    func resolveEvent(choice: EventChoice) {
        guard let event = store.currentEvent else { return }

        var success: Bool
        if store.cheats.eventsAlwaysSuccess {
            success = true
        } else {
            let roll = Int.random(in: 0...100)
            success = roll < choice.successChance
        }
        let effect = success ? choice.successEffect : choice.failEffect
        applyEffect(effect, forEvent: event)

        // 清除事件。
        store.currentEvent = nil
        // 只顯示「事件已處理」，不顯示成敗細節。
        appendEventLog("事件已處理。")
        showToast("事件已處理")
        HapticService.medium()
        autosaveNow()
    }

    private func applyEffect(_ effect: EventEffect, forEvent event: StoreEvent) {
        // 金錢。
        if effect.moneyChange != 0 {
            if effect.moneyChange > 0 {
                safeAddMoney(amount: effect.moneyChange, reason: "事件：\(event.title)")
            } else {
                let cost = -effect.moneyChange
                _ = safeSpendMoney(amount: cost, reason: "事件：\(event.title)")
                store.repairCostToday += cost   // 維修 / 罰款歸類
            }
        }
        // 名聲 / 滿意度 / 清潔度：clamp 安全。
        if effect.reputationChange != 0 {
            store.reputation = clamp(store.reputation + effect.reputationChange, 0, 100)
        }
        if effect.satisfactionChange != 0 {
            store.satisfaction = clamp(store.satisfaction + effect.satisfactionChange, 0, 100)
        }
        if effect.cleanlinessChange != 0 {
            store.cleanliness = clamp(store.cleanliness + effect.cleanlinessChange, 0, 100)
        }
        // 員工心情 / 忠誠 / 疲勞。
        if effect.employeeMoodChange != 0 || effect.employeeLoyaltyChange != 0 || effect.employeeFatigue != 0 {
            let hired = store.employees.indices.filter { store.employees[$0].hired }
            for i in hired {
                store.employees[i].mood = clamp(store.employees[i].mood + effect.employeeMoodChange, 0, 100)
                store.employees[i].loyalty = clamp(store.employees[i].loyalty + effect.employeeLoyaltyChange, 0, 100)
                store.employees[i].fatigue = clamp(store.employees[i].fatigue + effect.employeeFatigue, 0, 100)
            }
        }
        // 商品損失：平均分配到所有非服務架上商品。
        if effect.productLoss > 0 {
            applyProductLoss(effect.productLoss)
        }

        // 外掛：名聲鎖定 100。
        if store.cheats.maxReputationLocked { store.reputation = 100 }
        if store.cheats.customersAlwaysSatisfied { store.satisfaction = 100 }

        Self.clampInPlace(&store)
    }

    private func applyProductLoss(_ totalLoss: Int) {
        let targets = store.products.indices.filter {
            !store.products[$0].isService && (store.products[$0].shelfStock > 0 || store.products[$0].warehouseStock > 0)
        }
        guard !targets.isEmpty else { return }
        var remaining = totalLoss
        // 先扣架上，再扣倉庫。
        for i in targets {
            if remaining <= 0 { break }
            let onShelf = store.products[i].shelfStock
            let taken = min(onShelf, remaining)
            if taken > 0 {
                _ = safeRemoveShelfStock(productID: store.products[i].id, amount: taken, logFailure: false)
                remaining -= taken
            }
            if remaining > 0 {
                let inWarehouse = store.products[i].warehouseStock
                let takenW = min(inWarehouse, remaining)
                if takenW > 0 {
                    _ = safeRemoveWarehouseStock(productID: store.products[i].id, amount: takenW, logFailure: false)
                    remaining -= takenW
                }
            }
        }
        store.productLossToday += totalLoss - max(0, remaining)
    }

    /// 觸發測試事件（Debug 用）。
    func triggerTestEvent() {
        store.currentEvent = EventFactory.randomEvent()
    }

    // MARK: - Purchase (進貨)

    /// 進貨：買入數量商品到倉庫。資金不足時不可扣到負數。
    @discardableResult
    func purchaseProduct(productID: UUID, amount: Int) -> Bool {
        guard amount > 0 else { return false }
        guard let idx = productIndex[productID] else { return false }
        let product = store.products[idx]
        guard product.isUnlocked else {
            showToast("商品尚未解鎖")
            return false
        }
        let unitCost = Int(Double(product.buyPrice) * store.settings.difficulty.costMultiplier)
        let totalCost = unitCost * amount
        guard canAfford(totalCost) else {
            showToast("資金不足，無法進貨 \(product.name)")
            appendEventLog("資金不足，無法進貨 \(product.name) x\(amount)。")
            return false
        }
        guard safeSpendMoney(amount: totalCost, reason: "進貨 \(product.name) x\(amount)") else {
            showToast("資金不足，無法完成：進貨")
            return false
        }
        store.purchaseCostToday += totalCost
        safeAddWarehouseStock(productID: productID, amount: amount)
        HapticService.light()
        return true
    }

    // MARK: - Shelf Operations

    /// 從倉庫補到架上。
    @discardableResult
    func restockToShelf(productID: UUID, amount: Int) -> Bool {
        guard amount > 0 else { return false }
        guard let idx = productIndex[productID] else { return false }
        let product = store.products[idx]

        // 沒有對應設備不能上架。
        if !canPlaceOnShelf(product) {
            showToast("缺少對應貨架設備")
            return false
        }

        // 不能超過容量。
        let available = product.shelfCapacity - product.shelfStock
        let toMove = min(amount, available)
        guard toMove > 0 else {
            showToast("貨架已滿")
            return false
        }
        // 不能超過倉庫庫存。
        guard safeRemoveWarehouseStock(productID: productID, amount: toMove, logFailure: false) else {
            showToast("倉庫庫存不足")
            return false
        }
        safeAddShelfStock(productID: productID, amount: toMove)
        HapticService.light()
        return true
    }

    /// 補滿架上（受倉庫與容量限制）。
    @discardableResult
    func restockToFull(productID: UUID) -> Bool {
        guard let idx = productIndex[productID] else { return false }
        let need = store.products[idx].shelfCapacity - store.products[idx].shelfStock
        guard need > 0 else { return false }
        return restockToShelf(productID: productID, amount: need)
    }

    /// 下架：架上 -> 倉庫。
    @discardableResult
    func unshelf(productID: UUID, amount: Int) -> Bool {
        guard amount > 0 else { return false }
        guard safeRemoveShelfStock(productID: productID, amount: amount, logFailure: false) else {
            showToast("架上庫存不足")
            return false
        }
        safeAddWarehouseStock(productID: productID, amount: amount)
        return true
    }

    /// 檢查商品是否有對應貨架設備。
    private func canPlaceOnShelf(_ product: Product) -> Bool {
        if product.requiresColdStorage && upgradeLevel(.fridge) == 0 { return false }
        if product.requiresFrozen && upgradeLevel(.freezer) == 0 { return false }
        if product.requiresHotZone && upgradeLevel(.hotZone) == 0 { return false }
        return true
    }

    /// 快速補貨（總覽頁按鈕）：把所有能補的商品補一批。
    func quickRestock() {
        var didAny = false
        for p in store.products where p.isUnlocked && !p.isService {
            let need = p.shelfCapacity - p.shelfStock
            if need > 0 && p.warehouseStock > 0 {
                let toMove = min(need, p.warehouseStock, 10)
                if restockToShelf(productID: p.id, amount: toMove) {
                    didAny = true
                }
            }
        }
        showToast(didAny ? "已快速補貨" : "沒有需要補貨的商品")
    }

    // MARK: - Price Control

    func setSellPrice(productID: UUID, price: Int) {
        guard let idx = productIndex[productID] else { return }
        // 售價不可低於 1。
        store.products[idx].sellPrice = max(1, price)
    }

    func toggleOnSale(productID: UUID) {
        guard let idx = productIndex[productID] else { return }
        store.products[idx].isOnSale.toggle()
    }

    func toggleAutoRestock(productID: UUID) {
        guard let idx = productIndex[productID] else { return }
        store.products[idx].autoRestockEnabled.toggle()
    }

    // MARK: - Employee Management

    func hire(employeeID: UUID) -> Bool {
        guard let idx = store.employees.firstIndex(where: { $0.id == employeeID }) else { return false }
        guard !store.employees[idx].hired else { return false }
        // 解鎖全部員工外掛下可任意雇用；否則需未鎖定。
        store.employees[idx].hired = true
        appendEventLog("雇用了 \(store.employees[idx].name)。")
        HapticService.success()
        syncShifts()
        return true
    }

    func fire(employeeID: UUID) -> Bool {
        guard let idx = store.employees.firstIndex(where: { $0.id == employeeID }) else { return false }
        guard store.employees[idx].hired else { return false }
        let name = store.employees[idx].name
        store.employees[idx].hired = false
        store.employees[idx].assignedShift = nil
        store.employees[idx].isWorkingNow = false
        appendEventLog("解雇了 \(name)。")
        syncShifts()
        return true
    }

    @discardableResult
    func setWage(employeeID: UUID, wage: Int) -> Bool {
        guard let idx = store.employees.firstIndex(where: { $0.id == employeeID }) else { return false }
        store.employees[idx].hourlyWage = max(0, wage)
        return true
    }

    /// 發獎金。
    @discardableResult
    func giveBonus(employeeID: UUID, amount: Int) -> Bool {
        guard amount > 0 else { return false }
        guard let idx = store.employees.firstIndex(where: { $0.id == employeeID }) else { return false }
        guard store.employees[idx].hired else { return false }
        guard canAfford(amount) else {
            showToast("資金不足，無法發獎金")
            return false
        }
        guard safeSpendMoney(amount: amount, reason: "發放 \(store.employees[idx].name) 獎金") else { return false }
        store.salaryCostToday += amount
        store.employees[idx].mood = clamp(store.employees[idx].mood + 10, 0, 100)
        store.employees[idx].loyalty = clamp(store.employees[idx].loyalty + 8, 0, 100)
        store.employees[idx].quitRisk = clamp(store.employees[idx].quitRisk - 10, 0, 100)
        showToast("已發放獎金給 \(store.employees[idx].name)")
        HapticService.success()
        return true
    }

    /// 扣薪。
    @discardableResult
    func cutPay(employeeID: UUID, amount: Int) -> Bool {
        guard amount > 0 else { return false }
        guard let idx = store.employees.firstIndex(where: { $0.id == employeeID }) else { return false }
        guard store.employees[idx].hired else { return false }
        // 扣的是時薪，不可低於 0。
        let newWage = max(0, store.employees[idx].hourlyWage - amount)
        let diff = store.employees[idx].hourlyWage - newWage
        store.employees[idx].hourlyWage = newWage
        store.employees[idx].mood = clamp(store.employees[idx].mood - 8, 0, 100)
        store.employees[idx].loyalty = clamp(store.employees[idx].loyalty - 10, 0, 100)
        store.employees[idx].quitRisk = clamp(store.employees[idx].quitRisk + 12, 0, 100)
        appendEventLog("對 \(store.employees[idx].name) 扣薪 \(diff) 元。")
        return true
    }

    /// 訓練：花錢提升技能。
    @discardableResult
    func train(employeeID: UUID, cost: Int) -> Bool {
        guard cost > 0 else { return false }
        guard let idx = store.employees.firstIndex(where: { $0.id == employeeID }) else { return false }
        guard store.employees[idx].hired else { return false }
        guard canAfford(cost) else {
            showToast("資金不足，無法訓練")
            return false
        }
        guard safeSpendMoney(amount: cost, reason: "訓練 \(store.employees[idx].name)") else { return false }
        store.salaryCostToday += cost
        // 依職位提升對應技能。
        switch store.employees[idx].role {
        case .cashier:
            store.employees[idx].cashierSkill = clamp(store.employees[idx].cashierSkill + 8, 0, 100)
            store.employees[idx].serviceSkill = clamp(store.employees[idx].serviceSkill + 5, 0, 100)
        case .restocker:
            store.employees[idx].restockSkill = clamp(store.employees[idx].restockSkill + 8, 0, 100)
        case .cleaner:
            store.employees[idx].cleaningSkill = clamp(store.employees[idx].cleaningSkill + 8, 0, 100)
        case .manager:
            store.employees[idx].serviceSkill = clamp(store.employees[idx].serviceSkill + 5, 0, 100)
            store.employees[idx].cashierSkill = clamp(store.employees[idx].cashierSkill + 5, 0, 100)
        }
        store.employees[idx].efficiency = clamp(store.employees[idx].efficiency + 5, 0, 100)
        showToast("已訓練 \(store.employees[idx].name)")
        HapticService.success()
        return true
    }

    /// 安排班別。
    func assignShift(employeeID: UUID, shift: ShiftType?) {
        guard let idx = store.employees.firstIndex(where: { $0.id == employeeID }) else { return }
        guard store.employees[idx].hired else { return }
        // 先從舊班移除。
        if let old = store.employees[idx].assignedShift {
            if let oi = store.shifts.firstIndex(where: { $0.type == old }) {
                store.shifts[oi].employeeIDs.removeAll { $0 == employeeID }
            }
        }
        store.employees[idx].assignedShift = shift
        if let new = shift {
            if let ni = store.shifts.firstIndex(where: { $0.type == new }) {
                if !store.shifts[ni].employeeIDs.contains(employeeID) {
                    store.shifts[ni].employeeIDs.append(employeeID)
                }
            }
        }
        syncShifts()
    }

    // MARK: - Upgrades

    func upgradeLevel(_ type: UpgradeType) -> Int {
        store.upgrades.first { $0.type == type }?.level ?? 0
    }

    @discardableResult
    func buyUpgrade(type: UpgradeType) -> Bool {
        guard let idx = store.upgrades.firstIndex(where: { $0.type == type }) else { return false }
        guard !store.upgrades[idx].isMaxed else {
            showToast("已達最高等級")
            return false
        }
        let cost = store.upgrades[idx].nextCost
        guard canAfford(cost) else {
            showToast("資金不足，無法升級")
            return false
        }
        guard safeSpendMoney(amount: cost, reason: "升級 \(store.upgrades[idx].name)") else { return false }
        store.upgrades[idx].level += 1
        // 升級效果：擴充對應容量。
        applyUpgradeEffects()
        appendEventLog("升級了 \(store.upgrades[idx].name) 至 Lv.\(store.upgrades[idx].level)。")
        HapticService.success()
        autosaveNow()
        return true
    }

    /// 升級後重新套用容量效果到商品。
    private func applyUpgradeEffects() {
        let normalCap = 20 + upgradeLevel(.normalShelf) * 10
        let fridgeCap = 20 + upgradeLevel(.fridge) * 10
        let freezerCap = 20 + upgradeLevel(.freezer) * 10
        let hotCap = 20 + upgradeLevel(.hotZone) * 10

        for i in store.products.indices {
            switch store.products[i].shelfType {
            case .normal:
                store.products[i].shelfCapacity = normalCap
            case .chilled:
                store.products[i].shelfCapacity = fridgeCap
            case .frozen:
                store.products[i].shelfCapacity = freezerCap
            case .hotFood:
                store.products[i].shelfCapacity = hotCap
            case .counter:
                store.products[i].shelfCapacity = 999   // 櫃檯無上限
            }
            // 若現有庫存超過新容量，截斷。
            if store.products[i].shelfStock > store.products[i].shelfCapacity {
                store.products[i].shelfStock = store.products[i].shelfCapacity
            }
        }
    }

    // MARK: - Cheats

    func updateCheats(_ transform: (inout CheatSettings) -> Void) {
        transform(&store.cheats)
        // 開啟任一外掛即標記為外掛存檔。
        if store.cheats.anyCheatActive {
            store.cheats.cheatModeEnabled = true
            store.isCheatSave = true
        }
        // 套用外掛即時效果。
        if store.cheats.maxReputationLocked { store.reputation = 100 }
        if store.cheats.customersAlwaysSatisfied { store.satisfaction = 100 }
        if store.cheats.allProductsUnlocked {
            for i in store.products.indices { store.products[i].isUnlocked = true }
        }
        HapticService.enabled = store.settings.hapticEnabled
        autosaveNow()
    }

    /// 一鍵補滿全部倉庫（外掛按鈕）。
    func cheatFillAllWarehouse() {
        for i in store.products.indices where store.products[i].isUnlocked {
            store.products[i].warehouseStock = 999
        }
        showToast("已補滿全部倉庫")
    }

    /// 一鍵補滿全部貨架（外掛按鈕，不可超過容量）。
    func cheatFillAllShelves() {
        for i in store.products.indices where store.products[i].isUnlocked {
            store.products[i].shelfStock = store.products[i].shelfCapacity
        }
        showToast("已補滿全部貨架")
    }

    // MARK: - Settings

    func updateSettings(_ transform: (inout GameSettings) -> Void) {
        transform(&store.settings)
        HapticService.enabled = store.settings.hapticEnabled
        // 速度變動時重啟計時器。
        if store.isOpen { startTimer() }
        autosaveNow()
    }

    // MARK: - Save Management

    func autosaveNow() {
        validateBeforeSave()
        _ = SaveService.save(store)
    }

    func manualSave() {
        validateBeforeSave()
        if SaveService.save(store) {
            showToast("已存檔")
        } else {
            showToast("存檔失敗")
        }
    }

    func reloadSave() {
        if let loaded = SaveService.load() {
            var safe = loaded
            Self.clampInPlace(&safe)
            store = safe
            validateAfterLoad()
            showToast("已重新讀取存檔")
        } else {
            showToast("沒有可讀取的存檔")
        }
    }

    func resetGame() {
        let fresh = SaveService.reset()
        store = fresh
        rebuildProductIndex()
        applyUpgradeEffects()
        showToast("已重置遊戲")
    }

    func exportSave() -> String {
        do {
            return try SaveService.exportString(store)
        } catch {
            return ""
        }
    }

    func importSave(_ text: String) -> Bool {
        do {
            var decoded = try SaveService.importString(text)
            Self.clampInPlace(&decoded)
            _ = SaveService.save(decoded)
            store = decoded
            validateAfterLoad()
            applyUpgradeEffects()
            showToast("匯入成功")
            return true
        } catch {
            showToast("匯入失敗：\(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Log

    func appendEventLog(_ message: String) {
        store.eventLog.append("[Day\(store.day) \(String(format: "%02d", store.hour)):00] \(message)")
        if store.eventLog.count > 100 { store.eventLog.removeFirst() }
    }

    func appendDebugLog(_ message: String) {
        store.debugLog.append(message)
        if store.debugLog.count > 100 { store.debugLog.removeFirst() }
    }

    // ==========================================================
    //  安全方法（資料安全規則）
    //  這裡是整個遊戲「防止負數 / 超量」的核心。
    //  所有交易、庫存、事件效果都必須透過這裡。
    // ==========================================================

    /// 4. safeSpendMoney：安全扣錢。
    @discardableResult
    func safeSpendMoney(amount: Int, reason: String) -> Bool {
        if amount <= 0 { return false }
        // 外掛無限錢：不扣錢。
        if store.cheats.infiniteMoney { return true }
        if store.money < amount {
            appendEventLog("資金不足，無法完成：\(reason)")
            return false
        }
        store.money -= amount
        // 再 clamp 一次，永遠不為負。
        if store.money < 0 { store.money = 0 }
        return true
    }

    /// 5. safeAddMoney：安全加錢（套用倍率）。
    func safeAddMoney(amount: Int, reason: String) {
        if amount <= 0 { return }
        var final = amount
        if store.cheats.moneyMultiplier > 1 {
            final = Int(Double(amount) * store.cheats.moneyMultiplier)
        }
        store.money += max(0, final)
        if store.money < 0 { store.money = 0 }
    }

    /// 10. canAfford。
    func canAfford(_ amount: Int) -> Bool {
        if store.cheats.infiniteMoney { return true }
        return store.money >= amount
    }

    /// 6. safeAddWarehouseStock。
    func safeAddWarehouseStock(productID: UUID, amount: Int) {
        guard amount > 0 else { return }
        guard let idx = productIndex[productID] else { return }
        store.products[idx].warehouseStock += amount
        if store.products[idx].warehouseStock < 0 { store.products[idx].warehouseStock = 0 }
    }

    /// 7. safeRemoveWarehouseStock。
    @discardableResult
    func safeRemoveWarehouseStock(productID: UUID, amount: Int, logFailure: Bool = true) -> Bool {
        if amount <= 0 { return false }
        guard let idx = productIndex[productID] else { return false }
        if store.products[idx].warehouseStock < amount {
            if logFailure { appendEventLog("倉庫庫存不足：\(store.products[idx].name)") }
            return false
        }
        store.products[idx].warehouseStock -= amount
        if store.products[idx].warehouseStock < 0 { store.products[idx].warehouseStock = 0 }
        return true
    }

    /// 8. safeAddShelfStock：不可超過容量。
    func safeAddShelfStock(productID: UUID, amount: Int) {
        guard amount > 0 else { return }
        guard let idx = productIndex[productID] else { return }
        let cap = store.products[idx].shelfCapacity
        store.products[idx].shelfStock = min(cap, store.products[idx].shelfStock + amount)
        if store.products[idx].shelfStock < 0 { store.products[idx].shelfStock = 0 }
    }

    /// 9. safeRemoveShelfStock。
    @discardableResult
    func safeRemoveShelfStock(productID: UUID, amount: Int, logFailure: Bool = true) -> Bool {
        if amount <= 0 { return false }
        guard let idx = productIndex[productID] else { return false }
        if store.products[idx].shelfStock < amount {
            if logFailure { appendEventLog("架上庫存不足：\(store.products[idx].name)") }
            return false
        }
        store.products[idx].shelfStock -= amount
        if store.products[idx].shelfStock < 0 { store.products[idx].shelfStock = 0 }
        return true
    }

    // ==========================================================
    //  Clamp / Validate / Repair
    // ==========================================================

    /// 2. clampProduct。
    static func clampProduct(_ product: Product) -> Product {
        StoreDataValidator.clampProduct(product)
    }

    /// 3. clampEmployee。
    static func clampEmployee(_ employee: Employee) -> Employee {
        StoreDataValidator.clampEmployee(employee)
    }

    /// 1. clampStoreData + 11/12. validate。
    static func clampInPlace(_ store: inout StoreData) {
        StoreDataValidator.clamp(&store)
    }

    static func clampStoreData(_ store: inout StoreData) {
        clampInPlace(&store)
    }

    func clampStoreData() {
        Self.clampStoreData(&store)
        rebuildProductIndex()
    }

    func validateBeforeSave() {
        clampStoreData()
    }

    func validateAfterLoad() {
        clampStoreData()
    }

    /// 13. repairBrokenSave：Debug 修復按鈕。
    func repairBrokenSave() {
        Self.clampInPlace(&store)
        rebuildProductIndex()
        _ = SaveService.save(store)
        appendDebugLog("已執行完整資料修復。")
        showToast("已修復壞資料")
    }

    /// 14. runDataIntegrityCheck：掃描所有問題並回傳文字列表。
    func runDataIntegrityCheck() -> [String] {
        var issues: [String] = []

        if store.money < 0 { issues.append("發現資金為負數（\(store.money)），已修復為 0") }
        if store.currentCustomers < 0 { issues.append("發現顧客數為負數，已修復") }
        if store.checkoutQueue < 0 { issues.append("發現結帳排隊為負數，已修復") }
        if !(0...100).contains(store.reputation) { issues.append("名聲 \(store.reputation) 超出範圍，已修正") }
        if !(0...100).contains(store.satisfaction) { issues.append("滿意度 \(store.satisfaction) 超出範圍，已修正") }
        if !(0...100).contains(store.cleanliness) { issues.append("清潔度 \(store.cleanliness) 超出範圍，已修正") }

        for p in store.products {
            if p.warehouseStock < 0 { issues.append("發現商品 \(p.name) 倉庫庫存為負數，已修復") }
            if p.shelfStock < 0 { issues.append("發現商品 \(p.name) 架上庫存為負數，已修復") }
            if p.shelfStock > p.shelfCapacity { issues.append("發現 \(p.name) 架上數量超過貨架容量，已修正") }
            if p.shelfCapacity < 0 { issues.append("發現 \(p.name) 貨架容量為負數，已修正") }
            if p.sellPrice < 1 { issues.append("發現 \(p.name) 售價過低，已修正為 1") }
            if p.buyPrice < 0 { issues.append("發現 \(p.name) 進價為負數，已修正") }
        }
        for e in store.employees where e.hired {
            if !(0...100).contains(e.mood) { issues.append("員工 \(e.name) 心情異常，已修正") }
            if !(0...100).contains(e.fatigue) { issues.append("員工 \(e.name) 疲勞異常，已修正") }
            if !(0...100).contains(e.loyalty) { issues.append("員工 \(e.name) 忠誠異常，已修正") }
            if !(0...100).contains(e.quitRisk) { issues.append("員工 \(e.name) 離職風險異常，已修正") }
            if !(0...100).contains(e.lazyRisk) { issues.append("員工 \(e.name) 偷懶風險異常，已修正") }
        }
        // 排班 ID 檢查。
        let validIDs = Set(store.employees.map { $0.id })
        for s in store.shifts {
            let orphans = s.employeeIDs.filter { !validIDs.contains($0) }
            if !orphans.isEmpty { issues.append("班別 \(s.type.rawValue) 含有 \(orphans.count) 個不存在的員工 ID，已移除") }
        }

        // 修復。
        Self.clampInPlace(&store)
        _ = SaveService.save(store)

        return issues
    }

    // MARK: - Debug Test Buttons

    /// Debug：加 10000 現金。
    func debugAddMoney() {
        safeAddMoney(amount: 10000, reason: "Debug 加錢")
        appendDebugLog("Debug：+10000 現金")
    }

    /// Debug：清空現金。
    func debugClearMoney() {
        store.money = 0
        appendDebugLog("Debug：清空現金（測試資金不足）")
    }

    /// Debug：補滿全部倉庫。
    func debugFillWarehouse() {
        for i in store.products.indices { store.products[i].warehouseStock = 999 }
        appendDebugLog("Debug：補滿全部倉庫")
    }

    /// Debug：清空全部貨架。
    func debugClearShelves() {
        for i in store.products.indices { store.products[i].shelfStock = 0 }
        appendDebugLog("Debug：清空全部貨架")
    }

    /// Debug：製造負數庫存測試。
    func debugMakeNegativeStock() {
        guard let firstIdx = store.products.indices.first else { return }
        store.products[firstIdx].warehouseStock = -10
        store.products[firstIdx].shelfStock = -5
        appendDebugLog("Debug：已故意把 \(store.products[firstIdx].name) 庫存設為負數（測試修復）")
    }

    /// Debug：製造負數資金測試。
    func debugMakeNegativeMoney() {
        store.money = -999
        appendDebugLog("Debug：已故意把資金設為 -999（測試修復）")
    }

    // MARK: - Helpers for UI

    /// 缺貨商品數。
    var outOfStockCount: Int {
        store.products.filter { $0.isOnSale && $0.isUnlocked && $0.shelfStock == 0 && !$0.isService }.count
    }

    /// 正在上班員工數。
    var workingEmployeeCount: Int {
        store.employees.filter { $0.hired && $0.isWorkingNow }.count
    }

    /// 目前收銀速度（每小時可處理人數）。
    var checkoutCapacity: Int {
        let shift = currentShift(forHour: store.hour)
        let cashiers = workingEmployees(forShift: shift).filter { $0.role == .cashier || $0.role == .manager }
        let totalSkill = cashiers.reduce(0) { $0 + $1.cashierSkill + $1.efficiency / 2 }
        let boost = 1 + upgradeLevel(.register)
        return max(1, totalSkill / 40 * boost)
    }

    deinit {
        tickTimer?.invalidate()
    }
}
