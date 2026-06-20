//
//  EventFactory.swift
//  ConvenienceStoreBoss
//
//  內建 12 種突發事件。
//  注意：事件結果只會回傳「事件已處理」，實際數值影響由 GameViewModel 安全套用。
//

import Foundation

enum EventFactory {

    static func makeAll() -> [StoreEvent] {
        [
            // 1. 客人鬧事
            StoreEvent(
                title: "客人鬧事",
                description: "一名客人因為排隊太久在店內大聲抱怨，其他客人開始圍觀。",
                choices: [
                    EventChoice(title: "耐心處理", successChance: 80,
                                successEffect: EventEffect(reputationChange: 5, satisfactionChange: 8, employeeMoodChange: -5, message: "客人態度緩和了。"),
                                failEffect: EventEffect(satisfactionChange: -3, employeeMoodChange: -10, message: "處理過程有些波折。")),
                    EventChoice(title: "請他離開", successChance: 55,
                                successEffect: EventEffect(satisfactionChange: -5, message: "客人離開了。"),
                                failEffect: EventEffect(reputationChange: -8, satisfactionChange: -10, message: "客人在門口繼續抱怨。")),
                    EventChoice(title: "強制趕走", successChance: 30,
                                successEffect: EventEffect(reputationChange: -10, satisfactionChange: -8, message: "客人被趕走了。"),
                                failEffect: EventEffect(reputationChange: -18, satisfactionChange: -15, employeeMoodChange: -10, message: "事情鬧得有點大。"))
                ],
                eventType: .customerTrouble
            ),

            // 2. 商品過期
            StoreEvent(
                title: "商品過期",
                description: "有客人發現架上的商品疑似不新鮮。",
                choices: [
                    EventChoice(title: "立刻下架", successChance: 90,
                                successEffect: EventEffect(reputationChange: 3, productLoss: 5, message: "已下架有疑慮的商品。"),
                                failEffect: EventEffect(productLoss: 5, message: "商品已下架。")),
                    EventChoice(title: "打折賣出", successChance: 60,
                                successEffect: EventEffect(moneyChange: 30, reputationChange: -5, message: "打折出清了。"),
                                failEffect: EventEffect(reputationChange: -12, satisfactionChange: -8, productLoss: 3, message: "客人對品質有意見。")),
                    EventChoice(title: "裝沒看到", successChance: 20,
                                successEffect: EventEffect(reputationChange: -3, message: "暫時沒人發現。"),
                                failEffect: EventEffect(reputationChange: -15, satisfactionChange: -12, productLoss: 5, message: "被投訴了。"))
                ],
                eventType: .productExpired
            ),

            // 3. 員工抱怨薪水
            StoreEvent(
                title: "員工抱怨薪水",
                description: "某位員工覺得薪水太低，最近工作態度明顯變差。",
                choices: [
                    EventChoice(title: "加薪安撫", successChance: 95,
                                successEffect: EventEffect(moneyChange: -200, employeeMoodChange: 15, employeeLoyaltyChange: 12, message: "員工滿意了。"),
                                failEffect: EventEffect(moneyChange: -200, employeeMoodChange: 5, message: "員工沒那麼開心。")),
                    EventChoice(title: "發一次獎金", successChance: 75,
                                successEffect: EventEffect(moneyChange: -300, employeeMoodChange: 10, employeeLoyaltyChange: 5, message: "員工心情好轉。"),
                                failEffect: EventEffect(moneyChange: -300, employeeMoodChange: 2, message: "員工不太領情。")),
                    EventChoice(title: "警告他", successChance: 35,
                                successEffect: EventEffect(employeeMoodChange: -5, message: "員工暫時安靜。"),
                                failEffect: EventEffect(employeeMoodChange: -15, employeeLoyaltyChange: -15, message: "員工更不滿了。")),
                    EventChoice(title: "不處理", successChance: 10,
                                successEffect: EventEffect(employeeMoodChange: -5, message: "員工繼續抱怨。"),
                                failEffect: EventEffect(employeeMoodChange: -15, employeeLoyaltyChange: -20, message: "員工開始考慮離職。"))
                ],
                eventType: .employeeWageComplaint
            ),

            // 4. 員工遲到
            StoreEvent(
                title: "員工遲到",
                description: "早班員工遲到，收銀開始排隊。",
                choices: [
                    EventChoice(title: "自己頂班", successChance: 85,
                                successEffect: EventEffect(satisfactionChange: 2, message: "你親自上陣。"),
                                failEffect: EventEffect(satisfactionChange: -3, message: "忙了一陣子。")),
                    EventChoice(title: "扣薪處理", successChance: 70,
                                successEffect: EventEffect(moneyChange: 50, employeeMoodChange: -8, employeeLoyaltyChange: -5, message: "員工被扣薪。"),
                                failEffect: EventEffect(employeeMoodChange: -15, employeeLoyaltyChange: -10, message: "員工很不高興。")),
                    EventChoice(title: "放他一馬", successChance: 60,
                                successEffect: EventEffect(satisfactionChange: -3, employeeMoodChange: 5, employeeLoyaltyChange: 3, message: "員工感謝體諒。"),
                                failEffect: EventEffect(satisfactionChange: -8, message: "客人等得更久。"))
                ],
                eventType: .employeeLate
            ),

            // 5. 冷藏櫃故障
            StoreEvent(
                title: "冷藏櫃故障",
                description: "冷藏櫃溫度異常，冷藏商品可能報廢。",
                choices: [
                    EventChoice(title: "立即維修", successChance: 90,
                                successEffect: EventEffect(moneyChange: -500, reputationChange: 2, productLoss: 2, message: "維修完成。"),
                                failEffect: EventEffect(moneyChange: -500, productLoss: 5, message: "維修花了點時間。")),
                    EventChoice(title: "暫時撐著", successChance: 45,
                                successEffect: EventEffect(productLoss: 3, message: "暫時撐過去了。"),
                                failEffect: EventEffect(reputationChange: -8, productLoss: 12, message: "部分商品報廢。")),
                    EventChoice(title: "關閉冷藏櫃", successChance: 30,
                                successEffect: EventEffect(productLoss: 6, message: "已關閉冷藏櫃。"),
                                failEffect: EventEffect(satisfactionChange: -10, productLoss: 18, message: "大量商品損失。"))
                ],
                eventType: .fridgeBroken
            ),

            // 6. 熱門商品缺貨
            StoreEvent(
                title: "熱門商品缺貨",
                description: "熱門商品賣光，客人開始抱怨。",
                choices: [
                    EventChoice(title: "緊急進貨", successChance: 80,
                                successEffect: EventEffect(moneyChange: -300, satisfactionChange: 5, message: "緊急補貨成功。"),
                                failEffect: EventEffect(moneyChange: -300, satisfactionChange: -2, message: "補貨稍慢。")),
                    EventChoice(title: "推薦其他商品", successChance: 65,
                                successEffect: EventEffect(satisfactionChange: 2, message: "客人接受了替代品。"),
                                failEffect: EventEffect(reputationChange: -3, satisfactionChange: -8, message: "客人不太滿意。")),
                    EventChoice(title: "不處理", successChance: 20,
                                successEffect: EventEffect(satisfactionChange: -5, message: "客人有些失望。"),
                                failEffect: EventEffect(reputationChange: -8, satisfactionChange: -15, message: "客人抱怨連連。"))
                ],
                eventType: .hotItemShortage
            ),

            // 7. 稽查員突襲
            StoreEvent(
                title: "稽查員突襲",
                description: "稽查員突然來店檢查清潔與商品狀態。",
                choices: [
                    EventChoice(title: "立刻整理", successChance: 75,
                                successEffect: EventEffect(moneyChange: -100, reputationChange: 5, message: "整理得乾乾淨淨。"),
                                failEffect: EventEffect(moneyChange: -300, reputationChange: -3, message: "被記了幾點小缺失。")),
                    EventChoice(title: "正常應對", successChance: 55,
                                successEffect: EventEffect(message: "稽查順利通過。"),
                                failEffect: EventEffect(moneyChange: -500, reputationChange: -8, message: "被開了罰單。")),
                    EventChoice(title: "嘗試敷衍", successChance: 25,
                                successEffect: EventEffect(reputationChange: -2, message: "矇混過關。"),
                                failEffect: EventEffect(moneyChange: -800, reputationChange: -15, satisfactionChange: -5, message: "被抓到問題，重罰。"))
                ],
                eventType: .inspectorRaid
            ),

            // 8. 附近競爭店開幕
            StoreEvent(
                title: "附近競爭店開幕",
                description: "附近開了一間新的便利商店，客流量受到影響。",
                choices: [
                    EventChoice(title: "降價促銷", successChance: 70,
                                successEffect: EventEffect(moneyChange: -200, reputationChange: 3, satisfactionChange: 5, message: "客人回流了一些。"),
                                failEffect: EventEffect(moneyChange: -200, message: "促銷效果有限。")),
                    EventChoice(title: "提升服務", successChance: 65,
                                successEffect: EventEffect(reputationChange: 6, satisfactionChange: 6, employeeMoodChange: -3, message: "服務品質提升。"),
                                failEffect: EventEffect(reputationChange: 2, message: "改善需要時間。")),
                    EventChoice(title: "不理它", successChance: 30,
                                successEffect: EventEffect(reputationChange: -3, message: "客人略減。"),
                                failEffect: EventEffect(reputationChange: -10, satisfactionChange: -5, message: "客人明顯流失。"))
                ],
                eventType: .competitorOpening
            ),

            // 9. 半夜客流暴增
            StoreEvent(
                title: "半夜客流暴增",
                description: "半夜突然有大量客人進店。",
                choices: [
                    EventChoice(title: "加開收銀", successChance: 75,
                                successEffect: EventEffect(moneyChange: 200, satisfactionChange: 8, employeeFatigue: 0, message: "順利消化人潮。"),
                                failEffect: EventEffect(moneyChange: 100, employeeMoodChange: -5, message: "員工累壞了。")),
                    EventChoice(title: "臨時補貨", successChance: 60,
                                successEffect: EventEffect(moneyChange: 150, satisfactionChange: 5, message: "補貨及時。"),
                                failEffect: EventEffect(moneyChange: 50, satisfactionChange: -5, message: "補貨慢了一拍。")),
                    EventChoice(title: "讓員工撐住", successChance: 35,
                                successEffect: EventEffect(moneyChange: 100, employeeMoodChange: -8, message: "硬撐過去了。"),
                                failEffect: EventEffect(satisfactionChange: -10, employeeMoodChange: -15, message: "現場一片混亂。"))
                ],
                eventType: .midnightRush
            ),

            // 10. 收銀機故障
            StoreEvent(
                title: "收銀機故障",
                description: "收銀機突然故障，結帳速度大幅下降。",
                choices: [
                    EventChoice(title: "立即維修", successChance: 85,
                                successEffect: EventEffect(moneyChange: -400, message: "維修完成。"),
                                failEffect: EventEffect(moneyChange: -400, satisfactionChange: -3, message: "維修花了點時間。")),
                    EventChoice(title: "手動結帳", successChance: 60,
                                successEffect: EventEffect(satisfactionChange: -2, message: "改為手動結帳。"),
                                failEffect: EventEffect(satisfactionChange: -10, message: "排隊大爆滿。")),
                    EventChoice(title: "暫停營業", successChance: 40,
                                successEffect: EventEffect(moneyChange: -100, message: "暫停營業一陣子。"),
                                failEffect: EventEffect(moneyChange: -300, reputationChange: -5, satisfactionChange: -8, message: "客人撲空。"))
                ],
                eventType: .registerBroken
            ),

            // 11. 員工想離職
            StoreEvent(
                title: "員工想離職",
                description: "某位員工提出離職。",
                choices: [
                    EventChoice(title: "加薪挽留", successChance: 80,
                                successEffect: EventEffect(moneyChange: -300, employeeMoodChange: 15, employeeLoyaltyChange: 15, message: "員工決定留下。"),
                                failEffect: EventEffect(moneyChange: -300, employeeMoodChange: 5, message: "員工仍在考慮。")),
                    EventChoice(title: "發獎金慰留", successChance: 65,
                                successEffect: EventEffect(moneyChange: -400, employeeMoodChange: 12, employeeLoyaltyChange: 8, message: "員工被打動。"),
                                failEffect: EventEffect(moneyChange: -400, employeeMoodChange: 3, message: "員工心意已決。")),
                    EventChoice(title: "接受離職", successChance: 100,
                                successEffect: EventEffect(message: "員工離開了。"),
                                failEffect: EventEffect(message: "員工離開了。")),
                    EventChoice(title: "冷處理", successChance: 20,
                                successEffect: EventEffect(employeeMoodChange: -10, employeeLoyaltyChange: -15, message: "員工很失望。"),
                                failEffect: EventEffect(employeeMoodChange: -20, employeeLoyaltyChange: -25, message: "員工隔天就走了。"))
                ],
                eventType: .employeeResign
            ),

            // 12. 客人遺失物品
            StoreEvent(
                title: "客人遺失物品",
                description: "客人在店內遺失錢包。",
                choices: [
                    EventChoice(title: "妥善保管並公告", successChance: 90,
                                successEffect: EventEffect(reputationChange: 8, satisfactionChange: 5, message: "客人感激不盡。"),
                                failEffect: EventEffect(reputationChange: 3, message: "暫無人認領。")),
                    EventChoice(title: "交給警察", successChance: 80,
                                successEffect: EventEffect(reputationChange: 5, message: "已移交警方。"),
                                failEffect: EventEffect(reputationChange: 2, message: "處理完成。")),
                    EventChoice(title: "裝作沒看到", successChance: 25,
                                successEffect: EventEffect(reputationChange: -3, message: "沒人發現。"),
                                failEffect: EventEffect(reputationChange: -12, satisfactionChange: -8, message: "被監視器拍到了。"))
                ],
                eventType: .customerLostItem
            )
        ]
    }

    /// 隨機抽一個事件。重複呼叫會給出不同事件。
    static func randomEvent() -> StoreEvent {
        let all = makeAll()
        return all.randomElement() ?? all[0]
    }
}

// EventEffect.employeeFatigue 已是正式儲存欄位（見 StoreEvent.swift），可直接在事件中使用。
