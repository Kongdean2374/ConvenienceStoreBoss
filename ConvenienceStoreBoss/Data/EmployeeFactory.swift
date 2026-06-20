//
//  EmployeeFactory.swift
//  ConvenienceStoreBoss
//
//  內建 12 位可雇用員工。
//

import Foundation

enum EmployeeFactory {

    static func makeAll() -> [Employee] {
        [
            // 1. 阿豪 - 收銀員，低薪，收銀普通，補貨低，清潔普通
            Employee(name: "阿豪", role: .cashier, hourlyWage: 150, expectedWage: 170,
                     cashierSkill: 55, restockSkill: 25, cleaningSkill: 45, serviceSkill: 50,
                     mood: 70, loyalty: 55, efficiency: 55, quitRisk: 25, lazyRisk: 20),
            // 2. 小美 - 收銀員，薪資較高，服務高，收銀高
            Employee(name: "小美", role: .cashier, hourlyWage: 220, expectedWage: 230,
                     cashierSkill: 85, restockSkill: 50, cleaningSkill: 55, serviceSkill: 90,
                     mood: 80, loyalty: 75, efficiency: 80, quitRisk: 10, lazyRisk: 5),
            // 3. 阿哲 - 補貨員，補貨高，服務普通
            Employee(name: "阿哲", role: .restocker, hourlyWage: 160, expectedWage: 175,
                     cashierSkill: 30, restockSkill: 88, cleaningSkill: 60, serviceSkill: 50,
                     mood: 72, loyalty: 65, efficiency: 75, quitRisk: 18, lazyRisk: 10),
            // 4. 佳佳 - 清潔員，清潔高，忠誠高
            Employee(name: "佳佳", role: .cleaner, hourlyWage: 150, expectedWage: 160,
                     cashierSkill: 35, restockSkill: 45, cleaningSkill: 90, serviceSkill: 55,
                     mood: 78, loyalty: 88, efficiency: 70, quitRisk: 8, lazyRisk: 6),
            // 5. 大志 - 收銀員，速度快但忠誠低
            Employee(name: "大志", role: .cashier, hourlyWage: 180, expectedWage: 200,
                     cashierSkill: 80, restockSkill: 40, cleaningSkill: 40, serviceSkill: 60,
                     mood: 60, loyalty: 35, efficiency: 75, quitRisk: 45, lazyRisk: 30),
            // 6. 小芬 - 值班店長，全面能力中高但薪資高
            Employee(name: "小芬", role: .manager, hourlyWage: 300, expectedWage: 320,
                     cashierSkill: 80, restockSkill: 75, cleaningSkill: 70, serviceSkill: 85,
                     mood: 82, loyalty: 80, efficiency: 88, quitRisk: 12, lazyRisk: 8),
            // 7. 阿凱 - 補貨員，效率高但疲勞容易上升
            Employee(name: "阿凱", role: .restocker, hourlyWage: 170, expectedWage: 180,
                     cashierSkill: 35, restockSkill: 85, cleaningSkill: 50, serviceSkill: 45,
                     mood: 70, loyalty: 60, efficiency: 80, fatigue: 20, quitRisk: 22, lazyRisk: 15),
            // 8. 美玲 - 清潔員，清潔高但收銀低
            Employee(name: "美玲", role: .cleaner, hourlyWage: 155, expectedWage: 165,
                     cashierSkill: 20, restockSkill: 50, cleaningSkill: 92, serviceSkill: 50,
                     mood: 76, loyalty: 70, efficiency: 72, quitRisk: 14, lazyRisk: 10),
            // 9. 志明 - 收銀員，便宜但偷懶機率高
            Employee(name: "志明", role: .cashier, hourlyWage: 140, expectedWage: 170,
                     cashierSkill: 50, restockSkill: 30, cleaningSkill: 40, serviceSkill: 45,
                     mood: 60, loyalty: 40, efficiency: 50, quitRisk: 30, lazyRisk: 55),
            // 10. 雅婷 - 值班店長，服務高、穩定高
            Employee(name: "雅婷", role: .manager, hourlyWage: 310, expectedWage: 330,
                     cashierSkill: 78, restockSkill: 70, cleaningSkill: 75, serviceSkill: 92,
                     mood: 85, loyalty: 90, efficiency: 90, quitRisk: 6, lazyRisk: 5),
            // 11. 阿國 - 補貨員，薪資低但成長慢
            Employee(name: "阿國", role: .restocker, hourlyWage: 140, expectedWage: 150,
                     cashierSkill: 25, restockSkill: 60, cleaningSkill: 45, serviceSkill: 40,
                     mood: 68, loyalty: 65, efficiency: 55, quitRisk: 28, lazyRisk: 20),
            // 12. 小安 - 收銀員，新手，薪資低，可訓練
            Employee(name: "小安", role: .cashier, hourlyWage: 130, expectedWage: 150,
                     cashierSkill: 40, restockSkill: 35, cleaningSkill: 40, serviceSkill: 55,
                     mood: 75, loyalty: 60, efficiency: 45, quitRisk: 30, lazyRisk: 18)
        ]
    }
}
