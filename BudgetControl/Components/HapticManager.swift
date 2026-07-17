//
//  HapticManager.swift
//  Budget Control
//
//  Thin wrapper over UIFeedbackGenerator so call sites stay one-liners and the
//  haptic vocabulary is centralized. Used for transaction saves, goal
//  completion, and the floating add button.
//

import UIKit

enum HapticManager {
    /// A physical impact — used when a transaction is committed.
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    /// A success notification — used when a savings goal reaches 100%.
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    /// A warning notification — used when a budget crosses its 80% threshold.
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }

    /// An error notification — used when a backup restore fails.
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }

    /// A light tap — used for the floating add button.
    static func light() {
        impact(.light)
    }
}
