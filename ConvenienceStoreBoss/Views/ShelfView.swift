//
//  ShelfView.swift
//  ConvenienceStoreBoss
//
//  貨架頁：顯示所有已上架商品，提供補 1 / 補滿 / 下架。
//  （實際商品列共用 ProductListView(mode: .shelf)，此頁提供另一種入口與貨架容量總覽。）
//

import SwiftUI

struct ShelfView: View {
    @EnvironmentObject var vm: GameViewModel

    var body: some View {
        ProductListView(mode: .shelf)
    }
}
