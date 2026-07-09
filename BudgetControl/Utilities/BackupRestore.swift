//
//  BackupRestore.swift
//  Budget Control
//
//  Encodes/decodes JSON backups and applies them to SwiftData.
//  Supports the native iOS format and the original web-prototype format.
//

import Foundation
import SwiftData

enum BackupRestoreError: LocalizedError {
    case invalidFormat
    case restoreFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "This file is not a valid Budget Control backup."
        case .restoreFailed(let detail):
            return "Restore failed: \(detail)"
        }
    }
}

enum BackupRestore {

    // MARK: - Decode

    /// Parses native iOS backups and legacy web-prototype JSON exports.
    static func decodeBackup(from data: Data) throws -> BackupBundle {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let native = try? decoder.decode(BackupBundle.self, from: data) {
            return native
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw BackupRestoreError.invalidFormat
        }

        return try parseLegacyPrototype(json)
    }

    // MARK: - Apply

    /// Replaces all SwiftData records with the contents of a backup bundle.
    static func apply(_ backup: BackupBundle, context: ModelContext) throws {
        try context.delete(model: Transaction.self)
        try context.delete(model: Wallet.self)
        try context.delete(model: AppCategory.self)
        try context.delete(model: Trip.self)
        try context.delete(model: SavingsGoal.self)
        try context.delete(model: Subscription.self)
        try context.delete(model: RecurringRule.self)

        // Flush deletes before inserting rows that may reuse the same UUIDs.
        try context.save()
        context.processPendingChanges()

        backup.wallets.forEach { context.insert($0.toModel()) }
        backup.categories.forEach { context.insert($0.toModel()) }
        backup.trips.forEach { context.insert($0.toModel()) }
        backup.goals.forEach { context.insert($0.toModel()) }
        backup.subscriptions.forEach { context.insert($0.toModel()) }
        backup.recurringRules.forEach { context.insert($0.toModel()) }
        backup.transactions.forEach { context.insert($0.toModel()) }

        try context.save()
        context.processPendingChanges()
    }

    // MARK: - Summary

    static func summary(for backup: BackupBundle) -> String {
        let txCount = backup.transactions.count
        let walletCount = backup.wallets.count
        let categoryCount = backup.categories.count
        return """
        This backup contains \(txCount) transaction\(txCount == 1 ? "" : "s"), \
        \(walletCount) wallet\(walletCount == 1 ? "" : "s"), and \
        \(categoryCount) categor\(categoryCount == 1 ? "y" : "ies"). \
        Restoring will permanently replace all current data.
        """
    }

    // MARK: - Legacy Web Prototype

    private static func parseLegacyPrototype(_ json: [String: Any]) throws -> BackupBundle {
        guard json["transactions"] != nil else {
            throw BackupRestoreError.invalidFormat
        }

        let currencyCode = json["currencyCode"] as? String ?? "USD"
        let isDarkMode = (json["theme"] as? String) == "dark"

        let transactions = (json["transactions"] as? [[String: Any]] ?? []).map {
            parseLegacyTransaction($0, defaultCurrency: currencyCode)
        }

        let wallets = (json["wallets"] as? [[String: Any]] ?? []).map(parseLegacyWallet)
        let categories = parseLegacyCategories(json["categories"])
        let trips = (json["trips"] as? [[String: Any]] ?? []).map(parseLegacyTrip)
        let goals = (json["goals"] as? [[String: Any]] ?? []).map(parseLegacyGoal)
        let subscriptions = (json["subscriptions"] as? [[String: Any]] ?? []).map(parseLegacySubscription)
        let recurringRules = (json["recurring"] as? [[String: Any]] ?? []).map(parseLegacyRecurringRule)

        let budgetLimits = parseLegacyBudgetLimits(json["budgets"])
        let quickActions = parseLegacyQuickActions(json["quickActions"])

        let settings = BackupSettings(
            currencyCode: currencyCode,
            isDarkMode: isDarkMode,
            activeTripId: json["activeTrip"] as? String,
            budgetLimits: budgetLimits,
            quickActions: quickActions
        )

        return BackupBundle(
            transactions: transactions,
            wallets: wallets,
            categories: categories,
            trips: trips,
            goals: goals,
            subscriptions: subscriptions,
            recurringRules: recurringRules,
            settings: settings
        )
    }

    private static func parseLegacyTransaction(
        _ dict: [String: Any],
        defaultCurrency: String
    ) -> CodableTransaction {
        let categoryId = (dict["categoryId"] as? String)
            ?? (dict["category"] as? String)
            ?? ""
        let currencyCode = (dict["currencyCode"] as? String)
            ?? (dict["currency"] as? String)
            ?? defaultCurrency

        return CodableTransaction(
            id: legacyUUID(from: dict["id"]),
            type: dict["type"] as? String ?? "expense",
            amount: legacyDouble(dict["amount"]),
            currencyCode: currencyCode,
            categoryId: categoryId,
            walletId: dict["walletId"] as? String ?? "",
            note: dict["note"] as? String ?? "",
            tags: dict["tags"] as? [String] ?? [],
            tripId: dict["tripId"] as? String,
            date: parseLegacyDate(dict["date"]),
            fromRecurringId: (dict["fromRecurringId"] as? String)
                ?? (dict["fromRecurring"] as? String)
        )
    }

    private static func parseLegacyWallet(_ dict: [String: Any]) -> CodableWallet {
        CodableWallet(
            id: dict["id"] as? String ?? UUID().uuidString,
            name: dict["name"] as? String ?? "Wallet",
            emoji: dict["emoji"] as? String ?? "",
            colorHex: (dict["colorHex"] as? String) ?? (dict["color"] as? String) ?? "#7A9CC6",
            isDefault: dict["isDefault"] as? Bool ?? false
        )
    }

    private static func parseLegacyCategories(_ value: Any?) -> [CodableCategory] {
        if let flat = value as? [[String: Any]] {
            return flat.map { parseLegacyCategory($0, type: $0["type"] as? String ?? "expense") }
        }

        guard let grouped = value as? [String: Any] else { return [] }

        var categories: [CodableCategory] = []
        if let expense = grouped["expense"] as? [[String: Any]] {
            categories.append(contentsOf: expense.map { parseLegacyCategory($0, type: "expense") })
        }
        if let income = grouped["income"] as? [[String: Any]] {
            categories.append(contentsOf: income.map { parseLegacyCategory($0, type: "income") })
        }
        return categories
    }

    private static func parseLegacyCategory(_ dict: [String: Any], type: String) -> CodableCategory {
        CodableCategory(
            id: dict["id"] as? String ?? UUID().uuidString,
            label: dict["label"] as? String ?? "Category",
            emoji: dict["emoji"] as? String ?? "",
            colorHex: (dict["colorHex"] as? String) ?? (dict["color"] as? String) ?? "#7A9CC6",
            type: type,
            isDefault: dict["isDefault"] as? Bool ?? false
        )
    }

    private static func parseLegacyTrip(_ dict: [String: Any]) -> CodableTrip {
        CodableTrip(
            id: dict["id"] as? String ?? UUID().uuidString,
            name: dict["name"] as? String ?? "Trip",
            budget: legacyDouble(dict["budget"]),
            isActive: dict["isActive"] as? Bool ?? false
        )
    }

    private static func parseLegacyGoal(_ dict: [String: Any]) -> CodableGoal {
        CodableGoal(
            id: dict["id"] as? String ?? UUID().uuidString,
            name: dict["name"] as? String ?? "Goal",
            target: legacyDouble(dict["target"]),
            saved: legacyDouble(dict["saved"]),
            emoji: dict["emoji"] as? String ?? ""
        )
    }

    private static func parseLegacySubscription(_ dict: [String: Any]) -> CodableSubscription {
        CodableSubscription(
            id: dict["id"] as? String ?? UUID().uuidString,
            name: dict["name"] as? String ?? "Subscription",
            amount: legacyDouble(dict["amount"]),
            period: dict["period"] as? String ?? "monthly",
            emoji: dict["emoji"] as? String ?? ""
        )
    }

    private static func parseLegacyRecurringRule(_ dict: [String: Any]) -> CodableRecurringRule {
        CodableRecurringRule(
            id: dict["id"] as? String ?? UUID().uuidString,
            type: dict["type"] as? String ?? "expense",
            amount: legacyDouble(dict["amount"]),
            categoryId: (dict["categoryId"] as? String) ?? (dict["category"] as? String) ?? "",
            walletId: dict["walletId"] as? String ?? "",
            note: dict["note"] as? String ?? "",
            frequency: (dict["frequency"] as? String) ?? (dict["freq"] as? String) ?? "monthly",
            startDate: parseLegacyDate(dict["startDate"]),
            lastRun: parseLegacyDate(dict["lastRun"])
        )
    }

    private static func parseLegacyBudgetLimits(_ value: Any?) -> [String: Double] {
        guard let dict = value as? [String: Any] else { return [:] }
        return dict.compactMapValues { legacyDouble($0) }
    }

    private static func parseLegacyQuickActions(_ value: Any?) -> [QuickAction] {
        guard let rows = value as? [[String: Any]] else { return [] }

        return rows.prefix(6).map { dict in
            QuickAction(
                id: dict["id"].map { String(describing: $0) } ?? UUID().uuidString,
                type: dict["type"] as? String ?? "expense",
                amount: legacyDouble(dict["amount"]),
                categoryId: (dict["categoryId"] as? String) ?? (dict["category"] as? String) ?? "",
                walletId: dict["walletId"] as? String ?? "",
                note: dict["note"] as? String ?? ""
            )
        }
    }

    private static func legacyUUID(from value: Any?) -> UUID {
        if let uuid = value as? UUID { return uuid }
        if let string = value as? String, let uuid = UUID(uuidString: string) { return uuid }
        if let number = value as? NSNumber {
            var bytes = [UInt8](repeating: 0, count: 16)
            var hash = UInt64(abs(number.int64Value))
            for index in 0..<8 {
                bytes[index] = UInt8(hash & 0xFF)
                hash >>= 8
            }
            return UUID(uuid: (
                bytes[0], bytes[1], bytes[2], bytes[3],
                bytes[4], bytes[5], bytes[6], bytes[7],
                bytes[8], bytes[9], bytes[10], bytes[11],
                bytes[12], bytes[13], bytes[14], bytes[15]
            ))
        }
        return UUID()
    }

    private static func legacyDouble(_ value: Any?) -> Double {
        if let number = value as? NSNumber { return number.doubleValue }
        if let double = value as? Double { return double }
        if let string = value as? String { return Double(string.replacingOccurrences(of: ",", with: ".")) ?? 0 }
        return 0
    }

    private static func parseLegacyDate(_ value: Any?) -> Date {
        guard let string = value as? String else { return .now }

        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: string) { return date }

        let standard = ISO8601DateFormatter()
        if let date = standard.date(from: string) { return date }

        let formats = [
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd",
        ]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: string) { return date }
        }

        return .now
    }
}
