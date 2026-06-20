//
//  SaveService.swift
//  ConvenienceStoreBoss
//
//  本機存檔服務：使用 Codable + UserDefaults。
//  負責：儲存 / 讀取 / 重置 / 匯出 JSON / 匯入 JSON。
//

import Foundation

enum SaveError: LocalizedError {
    case noSave
    case decodeFailed(String)
    case encodeFailed(String)

    var errorDescription: String? {
        switch self {
        case .noSave: return "目前沒有存檔。"
        case .decodeFailed(let m): return "存檔讀取失敗：\(m)"
        case .encodeFailed(let m): return "存檔寫入失敗：\(m)"
        }
    }
}

enum SaveService {

    /// UserDefaults 存檔 key。
    private static let saveKey = "ConvenienceStoreBoss.save.v1"

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    // MARK: - Load

    /// 讀取存檔。沒有存檔回傳 nil。
    static func load() -> StoreData? {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else { return nil }
        do {
            return try decoder.decode(StoreData.self, from: data)
        } catch {
            // 舊存檔或壞存檔：回 nil，交給 ViewModel 重建新遊戲，避免 crash。
            return nil
        }
    }

    /// 讀取存檔，沒有就建立新遊戲。
    static func loadOrCreate() -> StoreData {
        load() ?? makeNewGame()
    }

    // MARK: - Save

    /// 儲存（會先 clamp 防呆）。
    @discardableResult
    static func save(_ data: StoreData) -> Bool {
        var safe = data
        // 存檔前先修正異常資料，避免壞資料被永久保存。
        StoreDataValidator.clamp(&safe)
        do {
            let raw = try encoder.encode(safe)
            UserDefaults.standard.set(raw, forKey: saveKey)
            return true
        } catch {
            return false
        }
    }

    /// 不做任何 clamp，原樣儲存（僅 Debug 用）。
    @discardableResult
    static func saveRaw(_ data: StoreData) -> Bool {
        do {
            let raw = try encoder.encode(data)
            UserDefaults.standard.set(raw, forKey: saveKey)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Reset

    static func reset() -> StoreData {
        let fresh = makeNewGame()
        UserDefaults.standard.removeObject(forKey: saveKey)
        save(fresh)
        return fresh
    }

    // MARK: - Import / Export

    /// 匯出存檔為 JSON 字串。
    static func exportString(_ data: StoreData) throws -> String {
        var safe = data
        StoreDataValidator.clamp(&safe)
        let raw = try encoder.encode(safe)
        guard let text = String(data: raw, encoding: .utf8) else {
            throw SaveError.encodeFailed("JSON encoding failed")
        }
        return text
    }

    /// 從 JSON 字串匯入存檔，並相容舊版 Base64 JSON 字串。
    static func importString(_ string: String) throws -> StoreData {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        let raw: Data
        if let jsonData = trimmed.data(using: .utf8),
           trimmed.first == "{" || trimmed.first == "[" {
            raw = jsonData
        } else if let legacyData = Data(base64Encoded: trimmed) {
            raw = legacyData
        } else {
            throw SaveError.decodeFailed("字串不是有效的 JSON 或 Base64 JSON")
        }
        do {
            var decoded = try decoder.decode(StoreData.self, from: raw)
            // 匯入後立刻修正，避免外部壞資料。
            StoreDataValidator.clamp(&decoded)
            return decoded
        } catch {
            throw SaveError.decodeFailed(error.localizedDescription)
        }
    }

    // MARK: - New Game

    /// 建立一個全新遊戲。
    static func makeNewGame() -> StoreData {
        var store = StoreData()
        store.products = ProductFactory.makeAll()
        store.employees = EmployeeFactory.makeAll()
        store.upgrades = UpgradeFactory.makeAll()
        store.shifts = [
            WorkShift(type: .morning, employeeIDs: []),
            WorkShift(type: .afternoon, employeeIDs: []),
            WorkShift(type: .night, employeeIDs: [])
        ]
        store.isOpen = false
        store.day = 1
        store.hour = 8
        store.money = 5000
        store.storeValue = 5000
        store.eventLog = ["歡迎來到便利店老闆模擬器，開始你的經營之路。"]
        return store
    }
}
