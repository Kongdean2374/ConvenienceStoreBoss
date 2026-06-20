//
//  ProductListView.swift
//  ConvenienceStoreBoss
//
//  商品列表：分類篩選、搜尋、進貨 / 貨架兩種模式共用。
//

import SwiftUI

struct ProductListView: View {
    var mode: ProductRowView.Mode
    @EnvironmentObject var vm: GameViewModel

    @State private var searchText: String = ""
    @State private var selectedCategory: ProductCategory? = nil

    var filteredProducts: [Product] {
        vm.store.products.filter { p in
            let passCategory = selectedCategory == nil || p.category == selectedCategory
            let passSearch = searchText.isEmpty || p.name.localizedCaseInsensitiveContains(searchText)
            // 貨架模式只顯示已解鎖商品。
            let passUnlock = mode == .purchase ? true : p.isUnlocked
            return passCategory && passSearch && passUnlock
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                searchBar
                categoryFilter
                productsList
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.secondary)
            TextField("搜尋商品名稱", text: $searchText)
                .textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button { searchText = "" } label: { Image(systemName: "xmark.circle.fill").foregroundColor(.secondary) }
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(title: "全部", category: nil)
                ForEach(ProductCategory.allCases) { cat in
                    categoryChip(title: cat.rawValue, category: cat)
                }
            }
        }
    }

    private func categoryChip(title: String, category: ProductCategory?) -> some View {
        let isSelected = selectedCategory == category
        return Button(action: { selectedCategory = category }) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }

    private var productsList: some View {
        LazyVStack(spacing: 12) {
            if filteredProducts.isEmpty {
                Text("沒有符合的商品")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 40)
            } else {
                ForEach(filteredProducts) { product in
                    ProductRowView(product: product, vm: vm, mode: mode)
                }
            }
        }
    }
}
