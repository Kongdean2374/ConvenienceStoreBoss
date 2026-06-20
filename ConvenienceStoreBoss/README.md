# ConvenienceStoreBoss · 便利店老闆模擬器

iOS SwiftUI 單機便利商店經營模擬遊戲。玩家扮演便利商店**老闆**，控制商品進貨、上架、售價、員工薪資與排班、店鋪升級、突發事件處理。

- 平台：iOS 17+
- 語言：Swift + SwiftUI
- 架構：MVVM
- 存檔：Codable + UserDefaults（本機，無伺服器、無登入、無內購）

---

## 一、專案結構

```
ConvenienceStoreBoss/
├─ ConvenienceStoreBossApp.swift        # App 進入點
├─ project.yml                          # XcodeGen 專案定義（用來產生 .xcodeproj）
├─ Models/                              # 資料模型
│  ├─ Enums.swift
│  ├─ Product.swift
│  ├─ Employee.swift
│  ├─ StoreEvent.swift
│  ├─ GameSettings.swift
│  ├─ CheatSettings.swift
│  ├─ Upgrade.swift
│  ├─ FinanceRecord.swift
│  └─ StoreData.swift
├─ Data/                                # 工廠（內建資料）
│  ├─ ProductFactory.swift              # 84 種商品
│  ├─ EmployeeFactory.swift             # 12 位員工
│  ├─ EventFactory.swift                # 12 種事件
│  └─ UpgradeFactory.swift              # 10 種升級
├─ Services/
│  ├─ SaveService.swift                 # UserDefaults 存檔 + 匯入匯出
│  └─ HapticService.swift               # 觸覺回饋
├─ ViewModels/
│  └─ GameViewModel.swift               # 核心邏輯 + 全部安全方法 + 遊戲循環
├─ Components/                          # UI 元件
│  ├─ PrimaryButton.swift
│  ├─ StatCard.swift
│  ├─ SectionCard.swift
│  ├─ ProgressStatView.swift
│  ├─ ProductRowView.swift
│  └─ EmployeeCardView.swift
├─ Views/                               # 頁面
│  ├─ RootTabView.swift
│  ├─ DashboardView.swift
│  ├─ BusinessView.swift
│  ├─ ProductListView.swift
│  ├─ ShelfView.swift
│  ├─ CheckoutView.swift
│  ├─ EmployeeView.swift
│  ├─ FinanceView.swift
│  ├─ UpgradeView.swift
│  ├─ SettingsView.swift
│  ├─ CheatView.swift
│  ├─ DebugView.swift
│  └─ EventModalView.swift
└─ .github/workflows/ios-build.yml      # GitHub Actions
```

---

## 二、本地開啟（兩種方式）

### 方式 A：用 XcodeGen（推薦，與 GitHub Actions 一致）

```bash
brew install xcodegen
cd ConvenienceStoreBoss
xcodegen generate
open ConvenienceStoreBoss.xcodeproj
```

### 方式 B：直接放進新 Xcode 專案

1. Xcode → File → New → Project → iOS App
2. Product Name：`ConvenienceStoreBoss`，Interface：SwiftUI，Language：Swift
3. 把上述所有 `.swift` 檔案拖進專案（勾選 Copy items if needed + Add to target）
4. 把 Deployment Target 設為 iOS 17.0
5. 執行

---

## 三、GitHub Actions 編譯

1. 把整個 `ConvenienceStoreBoss/` 資料夾推到 GitHub 倉庫（`main` 分支）。
2. push 後 workflow 自動執行；也可在 Actions 頁面手動觸發（workflow_dispatch）。
3. workflow 流程：
   - checkout
   - 安裝 XcodeGen 並執行 `xcodegen generate` 產生 `.xcodeproj`
   - `xcodebuild` 編譯 Release（`CODE_SIGNING_ALLOWED=NO`）
   - 把 `.app` 放進 `Payload/` 後 zip 成 `ConvenienceStoreBoss-unsigned.ipa`
   - 上傳 artifact：`ConvenienceStoreBoss-build`
4. 在 Actions 執行結果頁下方 Artifacts 區下載。

> **未簽名 IPA 無法直接安裝到手機**。因為沒有正式 Apple Developer 簽名 / Provisioning Profile，iOS 會拒絕安裝。你需要自行用有效憑證重新簽名後才能安裝。這是預期行為，不是 Bug。

---

## 四、核心防呆機制

所有資料異動都集中在 `GameViewModel` 的安全方法，UI 不直接改資料：

| 方法 | 用途 |
|------|------|
| `safeSpendMoney` | 安全扣錢，永不為負 |
| `safeAddMoney` | 安全加錢（套用金錢倍率） |
| `canAfford` | 檢查資金 |
| `safeAddWarehouseStock` / `safeRemoveWarehouseStock` | 倉庫庫存不為負 |
| `safeAddShelfStock` / `safeRemoveShelfStock` | 架上不為負、不超過容量 |
| `clampInPlace` | 修正整個 StoreData 異常 |
| `repairBrokenSave` | Debug 修復按鈕 |
| `runDataIntegrityCheck` | 掃描異常並回報 |

存檔前後都會 `validate`，避免壞資料被寫入或載入造成崩潰。

---

## 五、Debug 模式

設定頁 → 開啟「Debug 模式」→ 底部多出 Debug Tab。
功能：資料完整性檢查、自動修復、測試事件、故意製造負數庫存 / 負數資金以驗證修復能力。
Debug 頁面不是正常玩法的一部分。

---

## 六、限制聲明

- 不含 Firebase / 伺服器 / 登入 / 內購 / 廣告 / 多人連線。
- 不處理 Apple Developer 帳號、憑證、Provisioning Profile、TestFlight、App Store。
- artifact 為未簽名版本，安裝前需自行簽名。
