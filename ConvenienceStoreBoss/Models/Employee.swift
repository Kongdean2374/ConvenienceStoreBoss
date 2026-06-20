//
//  Employee.swift
//  ConvenienceStoreBoss
//
//  員工與排班資料模型。
//

import Foundation

struct Employee: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var role: EmployeeRole
    /// 實際時薪（>=0）。
    var hourlyWage: Int
    /// 員工期望時薪（>=0）。
    var expectedWage: Int
    /// 收銀能力（0~100）。
    var cashierSkill: Int
    /// 補貨能力（0~100）。
    var restockSkill: Int
    /// 清潔能力（0~100）。
    var cleaningSkill: Int
    /// 服務能力（0~100）。
    var serviceSkill: Int
    /// 心情（0~100）。
    var mood: Int
    /// 疲勞（0~100）。
    var fatigue: Int
    /// 忠誠度（0~100）。
    var loyalty: Int
    /// 當前效率（0~100），由心情、疲勞、薪資綜合計算。
    var efficiency: Int
    /// 是否已被雇用。
    var hired: Bool
    /// 被安排到的班別（nil 表示未排班）。
    var assignedShift: ShiftType?
    /// 目前是否正在上班（依時段判斷）。
    var isWorkingNow: Bool
    /// 離職風險（0~100）。
    var quitRisk: Int
    /// 偷懶風險（0~100）。
    var lazyRisk: Int

    init(
        id: UUID = UUID(),
        name: String,
        role: EmployeeRole,
        hourlyWage: Int,
        expectedWage: Int,
        cashierSkill: Int = 30,
        restockSkill: Int = 30,
        cleaningSkill: Int = 30,
        serviceSkill: Int = 30,
        mood: Int = 70,
        fatigue: Int = 0,
        loyalty: Int = 60,
        efficiency: Int = 60,
        hired: Bool = false,
        assignedShift: ShiftType? = nil,
        isWorkingNow: Bool = false,
        quitRisk: Int = 10,
        lazyRisk: Int = 10
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.hourlyWage = max(0, hourlyWage)
        self.expectedWage = max(0, expectedWage)
        self.cashierSkill = clamp(cashierSkill, 0, 100)
        self.restockSkill = clamp(restockSkill, 0, 100)
        self.cleaningSkill = clamp(cleaningSkill, 0, 100)
        self.serviceSkill = clamp(serviceSkill, 0, 100)
        self.mood = clamp(mood, 0, 100)
        self.fatigue = clamp(fatigue, 0, 100)
        self.loyalty = clamp(loyalty, 0, 100)
        self.efficiency = clamp(efficiency, 0, 100)
        self.hired = hired
        self.assignedShift = assignedShift
        self.isWorkingNow = isWorkingNow
        self.quitRisk = clamp(quitRisk, 0, 100)
        self.lazyRisk = clamp(lazyRisk, 0, 100)
    }
}

/// 一個班別對應的員工列表。
struct WorkShift: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var type: ShiftType
    var employeeIDs: [UUID]
}
