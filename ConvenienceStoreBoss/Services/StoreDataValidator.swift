//
//  StoreDataValidator.swift
//  ConvenienceStoreBoss
//
//  Pure data validation helpers used by both SaveService and GameViewModel.
//

import Foundation

enum StoreDataValidator {
    static func clampProduct(_ product: Product) -> Product {
        var p = product
        p.buyPrice = max(0, p.buyPrice)
        p.sellPrice = max(1, p.sellPrice)
        p.baseDemand = clamp(p.baseDemand, 0, 100)
        p.warehouseStock = max(0, p.warehouseStock)
        p.shelfCapacity = max(0, p.shelfCapacity)
        p.shelfStock = min(max(0, p.shelfStock), p.shelfCapacity)
        p.freshness = clamp(p.freshness, 0, 100)
        p.soldToday = max(0, p.soldToday)
        p.autoRestockThreshold = max(0, p.autoRestockThreshold)
        p.autoRestockAmount = max(0, p.autoRestockAmount)
        return p
    }

    static func clampEmployee(_ employee: Employee) -> Employee {
        var e = employee
        e.hourlyWage = max(0, e.hourlyWage)
        e.expectedWage = max(0, e.expectedWage)
        e.cashierSkill = clamp(e.cashierSkill, 0, 100)
        e.restockSkill = clamp(e.restockSkill, 0, 100)
        e.cleaningSkill = clamp(e.cleaningSkill, 0, 100)
        e.serviceSkill = clamp(e.serviceSkill, 0, 100)
        e.mood = clamp(e.mood, 0, 100)
        e.fatigue = clamp(e.fatigue, 0, 100)
        e.loyalty = clamp(e.loyalty, 0, 100)
        e.efficiency = clamp(e.efficiency, 0, 100)
        e.quitRisk = clamp(e.quitRisk, 0, 100)
        e.lazyRisk = clamp(e.lazyRisk, 0, 100)
        return e
    }

    static func clamp(_ store: inout StoreData) {
        store.money = max(0, store.money)
        store.reputation = clamp(store.reputation, 0, 100)
        store.satisfaction = clamp(store.satisfaction, 0, 100)
        store.cleanliness = clamp(store.cleanliness, 0, 100)
        store.currentCustomers = max(0, store.currentCustomers)
        store.checkoutQueue = max(0, store.checkoutQueue)

        store.totalRevenueToday = max(0, store.totalRevenueToday)
        store.purchaseCostToday = max(0, store.purchaseCostToday)
        store.salaryCostToday = max(0, store.salaryCostToday)
        store.repairCostToday = max(0, store.repairCostToday)
        store.productLossToday = max(0, store.productLossToday)
        store.totalEarned = max(0, store.totalEarned)
        store.pendingCheckoutRevenue = max(0, store.pendingCheckoutRevenue)

        store.products = store.products.map { clampProduct($0) }
        store.employees = store.employees.map { clampEmployee($0) }

        let validEmployeeIDs = Set(store.employees.filter { $0.hired }.map { $0.id })
        for si in store.shifts.indices {
            store.shifts[si].employeeIDs = store.shifts[si].employeeIDs.filter { validEmployeeIDs.contains($0) }
        }

        if store.hour < 0 { store.hour = 0 }
        if store.hour > 23 { store.hour = store.hour % 24 }
        if store.day < 1 { store.day = 1 }

        if store.cheats.maxReputationLocked { store.reputation = 100 }
        if store.cheats.customersAlwaysSatisfied { store.satisfaction = 100 }
        if store.cheats.employeesAlwaysHappy {
            for i in store.employees.indices where store.employees[i].hired {
                store.employees[i].mood = 100
                store.employees[i].fatigue = 0
            }
        }
    }
}
