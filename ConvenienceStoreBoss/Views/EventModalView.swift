//
//  EventModalView.swift
//  ConvenienceStoreBoss
//
//  突發事件彈窗。玩家選完後只顯示「事件已處理」。
//

import SwiftUI

struct EventModalView: View {
    let event: StoreEvent
    @EnvironmentObject var vm: GameViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 24) {
            // 標頭
            VStack(spacing: 12) {
                Image(systemName: eventIcon)
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
                Text(event.title)
                    .font(.title2.bold())
                Text(event.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal)
            }
            .padding(.top, 20)

            Divider()

            // 選項
            VStack(spacing: 12) {
                ForEach(event.choices) { choice in
                    Button {
                        vm.resolveEvent(choice: choice)
                        dismiss()
                    } label: {
                        Text(choice.title)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal)

            Spacer(minLength: 0)

            Text("事件結果將不會直接顯示，請留意店鋪數值變化。")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.bottom, 16)
        }
        .padding()
        .presentationDetents([.medium, .large])
    }

    private var eventIcon: String {
        switch event.eventType {
        case .customerTrouble: return "person.crop.circle.badge.exclamationmark"
        case .productExpired: return "calendar.badge.exclamationmark"
        case .employeeWageComplaint: return "money.rubl.circle"
        case .employeeLate: return "clock.badge.exclamationmark"
        case .fridgeBroken: return "snowflake.circle"
        case .hotItemShortage: return "cart.badge.questionmark"
        case .inspectorRaid: return "magnifyingglass.circle"
        case .competitorOpening: return "building.2"
        case .midnightRush: return "moon.stars"
        case .registerBroken: return "creditcard.and.123"
        case .employeeResign: return "person.fill.xmark"
        case .customerLostItem: return "questionmark.folder"
        }
    }
}
