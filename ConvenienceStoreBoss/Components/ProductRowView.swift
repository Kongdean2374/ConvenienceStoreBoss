//
//  ProductRowView.swift
//  ConvenienceStoreBoss
//
//  單一商品列。用於商品進貨頁與貨架頁共用。
//  所有操作都透過 GameViewModel 的安全方法，不在 View 裡直接改資料。
//

import SwiftUI

struct ProductRowView: View {
    let product: Product
    @ObservedObject var vm: GameViewModel
    var mode: Mode = .purchase
    @State private var priceInput: String = ""

    enum Mode {
        case purchase   // 進貨：顯示買入按鈕
        case shelf      // 貨架：顯示上架 / 下架按鈕
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // ===== 第一行：名稱、分類、狀態 =====
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(product.name)
                            .font(.system(.headline, design: .default))
                            .strikethrough(!product.isUnlocked, color: .secondary)
                        if !product.isUnlocked {
                            Text("未解鎖 Lv.\(product.unlockedLevel)")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(4)
                        }
                    }
                    HStack(spacing: 8) {
                        Text(product.category.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.15))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                        Text(product.shelfType.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if product.requiresColdStorage { Label("冷", systemImage: "snowflake").labelStyle(.titleAndIcon).font(.caption2).foregroundColor(.cyan) }
                        if product.requiresFrozen { Label("凍", systemImage: "snow").labelStyle(.titleAndIcon).font(.caption2).foregroundColor(.indigo) }
                        if product.requiresHotZone { Label("熱", systemImage: "flame").labelStyle(.titleAndIcon).font(.caption2).foregroundColor(.orange) }
                    }
                }
                Spacer()
                // 販售開關
                Toggle("", isOn: Binding(
                    get: { product.isOnSale },
                    set: { _ in vm.toggleOnSale(productID: product.id) }
                ))
                .labelsHidden()
                .disabled(!product.isUnlocked)
            }

            // ===== 第二行：數值區 =====
            HStack(spacing: 12) {
                priceBlock(title: "進價", value: "$\(product.buyPrice)", color: .red)
                priceBlock(title: "售價", value: "$\(product.sellPrice)", color: .green)
                priceBlock(title: "倉庫", value: "\(product.warehouseStock)", color: .brown)
                priceBlock(title: "架上", value: "\(product.shelfStock)/\(product.shelfCapacity)", color: .purple)
            }

            // ===== 第三行：需求度、新鮮度 =====
            HStack(spacing: 16) {
                if !product.isService {
                    ProgressStatView(title: "新鮮", value: product.freshness, icon: "leaf", showNumber: true)
                        .frame(maxWidth: .infinity)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("需求度").font(.caption2).foregroundColor(.secondary)
                    HStack(spacing: 2) {
                        ForEach(0..<5) { i in
                            Image(systemName: i < (product.baseDemand / 20) ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                        }
                    }
                }
            }

            // ===== 第四行：售價調整 =====
            HStack {
                Text("售價")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("\(product.sellPrice)", text: $priceInput)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                Button("套用") {
                    if let v = Int(priceInput), v >= 1 {
                        vm.setSellPrice(productID: product.id, price: v)
                        priceInput = ""
                    } else {
                        vm.showToast("售價不可低於 1")
                    }
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.15))
                .cornerRadius(6)
                Spacer()
                Button(product.autoRestockEnabled ? "自動補：開" : "自動補：關") {
                    vm.toggleAutoRestock(productID: product.id)
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((product.autoRestockEnabled ? Color.green : Color.gray).opacity(0.15))
                .cornerRadius(6)
            }

            // ===== 第五行：操作按鈕（依模式不同）=====
            if mode == .purchase {
                HStack(spacing: 8) {
                    purchaseButton(amount: 1)
                    purchaseButton(amount: 10)
                    purchaseButton(amount: 50)
                }
            } else {
                HStack(spacing: 8) {
                    actionButton(title: "補 1", icon: "arrow.up.to.line.compact", color: .blue) {
                        _ = vm.restockToShelf(productID: product.id, amount: 1)
                    }
                    actionButton(title: "補滿", icon: "arrow.up.to.line", color: .green) {
                        _ = vm.restockToFull(productID: product.id)
                    }
                    actionButton(title: "下架", icon: "arrow.down.to.line", color: .orange) {
                        _ = vm.unshelf(productID: product.id, amount: 1)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Subviews

    private func priceBlock(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption2).foregroundColor(.secondary)
            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func purchaseButton(amount: Int) -> some View {
        let unitCost = Int(Double(product.buyPrice) * vm.store.settings.difficulty.costMultiplier)
        let total = unitCost * amount
        let afford = vm.canAfford(total)
        return Button(action: {
            _ = vm.purchaseProduct(productID: product.id, amount: amount)
        }) {
            VStack(spacing: 2) {
                Text("買 \(amount)").font(.caption).fontWeight(.bold)
                Text("$\(total)").font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(afford ? Color.blue.opacity(0.15) : Color.gray.opacity(0.1))
            .foregroundColor(afford ? .blue : .secondary)
            .cornerRadius(8)
        }
        .disabled(!product.isUnlocked || !afford)
    }

    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                Text(title).font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(8)
        }
    }
}
