//
//  HapticService.swift
//  ConvenienceStoreBoss
//
//  觸覺回饋與音效（音效僅佔位，不引入第三方套件）。
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum HapticService {

    /// 是否允許觸覺回饋。由 GameViewModel 同步。
    static var enabled: Bool = true

    static func light() { trigger(.light) }
    static func medium() { trigger(.medium) }
    static func heavy() { trigger(.heavy) }
    static func success() { triggerNotification(.success) }
    static func warning() { triggerNotification(.warning) }
    static func error() { triggerNotification(.error) }

    private static func trigger(_ style: HapticStyle) {
        guard enabled else { return }
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: style.uiKitStyle)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }

    private static func triggerNotification(_ type: NotificationType) {
        guard enabled else { return }
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type.uiKitType)
        #endif
    }
}

private enum HapticStyle {
    case light, medium, heavy
    #if canImport(UIKit)
    var uiKitStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        switch self {
        case .light: return .light
        case .medium: return .medium
        case .heavy: return .heavy
        }
    }
    #endif
}

private enum NotificationType {
    case success, warning, error
    #if canImport(UIKit)
    var uiKitType: UINotificationFeedbackGenerator.FeedbackType {
        switch self {
        case .success: return .success
        case .warning: return .warning
        case .error: return .error
        }
    }
    #endif
}
