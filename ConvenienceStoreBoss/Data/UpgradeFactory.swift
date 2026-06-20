//
//  UpgradeFactory.swift
//  ConvenienceStoreBoss
//
//  內建 10 種店鋪升級。
//

import Foundation

enum UpgradeFactory {

    static func makeAll() -> [Upgrade] {
        [
            Upgrade(name: "一般貨架升級", description: "提高一般貨架容量，可上架更多商品。", maxLevel: 5, baseCost: 800, type: .normalShelf),
            Upgrade(name: "冷藏櫃升級", description: "擴大冷藏櫃容量，允許更多冷藏商品上架。", maxLevel: 5, baseCost: 1500, type: .fridge),
            Upgrade(name: "冷凍櫃升級", description: "擴大冷凍櫃容量，允許更多冷凍商品上架。", maxLevel: 5, baseCost: 1800, type: .freezer),
            Upgrade(name: "熱食區升級", description: "擴大熱食區，提高熱食銷量。", maxLevel: 5, baseCost: 1600, type: .hotZone),
            Upgrade(name: "收銀機升級", description: "升級收銀設備，提高結帳速度。", maxLevel: 5, baseCost: 1200, type: .register),
            Upgrade(name: "倉庫容量升級", description: "擴大倉庫，提高庫存上限。", maxLevel: 5, baseCost: 2000, type: .warehouse),
            Upgrade(name: "清潔設備升級", description: "提升清潔設備，降低清潔度下降速度。", maxLevel: 5, baseCost: 1000, type: .cleaningGear),
            Upgrade(name: "監視器升級", description: "加裝監視器，降低偷懶與負面事件發生。", maxLevel: 5, baseCost: 1400, type: .camera),
            Upgrade(name: "員工休息室升級", description: "改善休息環境，降低員工疲勞。", maxLevel: 5, baseCost: 2500, type: .breakRoom),
            Upgrade(name: "店面裝潢升級", description: "提升店面裝潢，提高名聲與客流。", maxLevel: 5, baseCost: 3000, type: .decoration)
        ]
    }
}
