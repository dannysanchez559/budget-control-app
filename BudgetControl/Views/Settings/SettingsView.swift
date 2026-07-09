//
//  SettingsView.swift
//  Budget Control
//
//  Appearance, currency, backup/restore, about.
//  Phase 4 screen 7 — functional settings.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var store
    @Environment(\.modelContext) private var modelContext

    // Full model snapshots for export/backup and CSV id resolution.
    @Query private var transactions: [Transaction]
    @Query private var wallets: [Wallet]
    @Query private var categories: [AppCategory]
    @Query private var trips: [Trip]
    @Query private var goals: [SavingsGoal]
    @Query private var subscriptions: [Subscription]
    @Query private var recurringRules: [RecurringRule]

    @State private var showingCurrencyPicker = false

    // Export file URLs, regenerated each time the sheet appears.
    @State private var csvURL: URL?
    @State private var backupURL: URL?

    // Restore flow.
    @State private var showingImporter = false
    @State private var pendingBackup: BackupBundle?
    @State private var showingRestoreConfirm = false
    @State private var resultMessage: String?
    @State private var showingResultAlert = false

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            List {
                appearanceSection(store: store)
                currencySection
                dataSection
                aboutSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppTheme.Colors.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.appSans(AppTheme.Typography.fontBody, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.appSans(AppTheme.Typography.fontBody, weight: .semibold))
                }
            }
            .sheet(isPresented: $showingCurrencyPicker) {
                CurrencyPickerView()
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.json]
            ) { result in
                handleImport(result)
            }
            .alert("Replace all data?", isPresented: $showingRestoreConfirm) {
                Button("Cancel", role: .cancel) { pendingBackup = nil }
                Button("Replace", role: .destructive) { performRestore() }
            } message: {
                if let pendingBackup {
                    Text(BackupRestore.summary(for: pendingBackup))
                }
            }
            .alert("Restore", isPresented: $showingResultAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(resultMessage ?? "")
            }
            .onAppear(perform: regenerateExports)
            .onChange(of: transactions.count) { _, _ in regenerateExports() }
        }
    }

    // MARK: - Section 1: Appearance

    private func appearanceSection(store: DataStore) -> some View {
        @Bindable var store = store
        return Section {
            Toggle(isOn: $store.isDarkMode) {
                Label {
                    Text("Dark mode")
                        .font(.appSans(AppTheme.Typography.fontBody))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                } icon: {
                    Image(systemName: "moon.fill")
                        .foregroundStyle(AppTheme.Colors.accent)
                }
            }
            .tint(AppTheme.Colors.accent)
        } header: {
            sectionHeader("Appearance")
        }
    }

    // MARK: - Section 2: Currency

    private var currencySection: some View {
        Section {
            Button {
                showingCurrencyPicker = true
            } label: {
                HStack {
                    Label {
                        Text("Display currency")
                            .font(.appSans(AppTheme.Typography.fontBody))
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                    } icon: {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundStyle(AppTheme.Colors.accent)
                    }
                    Spacer()
                    Text(store.currencyCode)
                        .font(.appSans(AppTheme.Typography.fontBody))
                        .foregroundStyle(AppTheme.Colors.textMuted)
                    Image(systemName: "chevron.right")
                        .font(.appSans(AppTheme.Typography.fontLabel, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.textMuted)
                }
            }
        } header: {
            sectionHeader("Currency")
        }
    }

    // MARK: - Section 3: Data

    private var dataSection: some View {
        Section {
            if let csvURL {
                ShareLink(item: csvURL) {
                    dataRow(icon: "tablecells", label: "Export CSV")
                }
            }
            if let backupURL {
                ShareLink(item: backupURL) {
                    dataRow(icon: "arrow.up.doc", label: "Backup JSON")
                }
            }
            Button {
                showingImporter = true
            } label: {
                dataRow(icon: "arrow.down.doc", label: "Restore from Backup")
            }
        } header: {
            sectionHeader("Data")
        } footer: {
            Text("Export your transactions as a spreadsheet, or back up and restore your full database as a JSON file.")
                .font(.appSans(AppTheme.Typography.fontLabel))
                .foregroundStyle(AppTheme.Colors.textMuted)
        }
    }

    private func dataRow(icon: String, label: String) -> some View {
        Label {
            Text(label)
                .font(.appSans(AppTheme.Typography.fontBody))
                .foregroundStyle(AppTheme.Colors.textPrimary)
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.Colors.accent)
        }
    }

    // MARK: - Section 4: About

    private var aboutSection: some View {
        Section {
            HStack {
                Label {
                    Text("Version")
                        .font(.appSans(AppTheme.Typography.fontBody))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                } icon: {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(AppTheme.Colors.accent)
                }
                Spacer()
                Text(versionString)
                    .font(.appSans(AppTheme.Typography.fontBody))
                    .foregroundStyle(AppTheme.Colors.textMuted)
            }
        } header: {
            sectionHeader("About")
        }
    }

    private var versionString: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(short) (\(build))"
    }

    // MARK: - Shared Header

    private func sectionHeader(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.appSans(AppTheme.Typography.fontCaption, weight: .semibold))
            .tracking(1.2)
            .foregroundStyle(AppTheme.Colors.textMuted)
    }

    // MARK: - Export Generation

    private func regenerateExports() {
        csvURL = makeCSVFile()
        backupURL = makeBackupFile()
    }

    /// Builds the CSV file and writes it to the temp directory. Returns nil on failure.
    private func makeCSVFile() -> URL? {
        let walletNames = Dictionary(uniqueKeysWithValues: wallets.map { ($0.id, $0.name) })
        let categoryLabels = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0.label) })

        let isoFormatter = ISO8601DateFormatter()
        let header = "id,date,type,amount,currency,category,wallet,note,tags"

        let rows = transactions
            .sorted { $0.date > $1.date }
            .map { tx -> String in
                let fields = [
                    tx.id.uuidString,
                    isoFormatter.string(from: tx.date),
                    tx.type,
                    String(format: "%.2f", tx.amount),
                    tx.currencyCode,
                    categoryLabels[tx.categoryId] ?? tx.categoryId,
                    walletNames[tx.walletId] ?? tx.walletId,
                    tx.note,
                    tx.tags.joined(separator: ";"),
                ]
                return fields.map(csvEscape).joined(separator: ",")
            }

        let csv = ([header] + rows).joined(separator: "\n")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("budget-control-transactions.csv")
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    /// Wraps a CSV field in quotes and escapes embedded quotes.
    private func csvEscape(_ value: String) -> String {
        "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    /// Encodes the full database to a JSON file in the temp directory. Returns nil on failure.
    private func makeBackupFile() -> URL? {
        let bundle = BackupBundle(
            transactions: transactions.map(CodableTransaction.init),
            wallets: wallets.map(CodableWallet.init),
            categories: categories.map(CodableCategory.init),
            trips: trips.map(CodableTrip.init),
            goals: goals.map(CodableGoal.init),
            subscriptions: subscriptions.map(CodableSubscription.init),
            recurringRules: recurringRules.map(CodableRecurringRule.init),
            settings: BackupSettings(
                currencyCode: store.currencyCode,
                isDarkMode: store.isDarkMode,
                activeTripId: store.activeTripId,
                budgetLimits: store.budgetLimits,
                quickActions: store.quickActions
            )
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("budget-control-backup.json")
        do {
            let data = try encoder.encode(bundle)
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    // MARK: - Restore

    private func handleImport(_ result: Result<URL, Error>) {
        switch result {
        case .failure(let error):
            resultMessage = "Could not open the file: \(error.localizedDescription)"
            showingResultAlert = true
        case .success(let url):
            let needsAccess = url.startAccessingSecurityScopedResource()
            defer { if needsAccess { url.stopAccessingSecurityScopedResource() } }
            do {
                let data = try Data(contentsOf: url)
                pendingBackup = try BackupRestore.decodeBackup(from: data)
                showingRestoreConfirm = true
            } catch {
                resultMessage = (error as? LocalizedError)?.errorDescription
                    ?? "This file is not a valid Budget Control backup."
                showingResultAlert = true
            }
        }
    }

    private func performRestore() {
        guard let backup = pendingBackup else { return }
        defer { pendingBackup = nil }

        do {
            try BackupRestore.apply(backup, context: modelContext)

            if let settings = backup.settings {
                applyRestoredSettings(settings)
            } else {
                // Legacy backups — derive the active trip from restored SwiftData flags.
                let activeTrip = (try? modelContext.fetch(FetchDescriptor<Trip>()))?.first { $0.isActive }
                store.activeTripId = activeTrip?.id
                syncTripActiveFlags(activeId: activeTrip?.id)
            }

            regenerateExports()
            let count = backup.transactions.count
            resultMessage = count > 0
                ? "Restored \(count) transaction\(count == 1 ? "" : "s") and all other backup data."
                : "Restore completed, but this backup contains no transactions."
        } catch {
            resultMessage = (error as? LocalizedError)?.errorDescription
                ?? "Restore failed: \(error.localizedDescription)"
        }
        showingResultAlert = true
    }

    private func applyRestoredSettings(_ settings: BackupSettings) {
        store.currencyCode = settings.currencyCode ?? store.currencyCode
        store.isDarkMode = settings.isDarkMode ?? store.isDarkMode
        store.budgetLimits = settings.budgetLimits ?? [:]
        store.quickActions = settings.quickActions ?? []
        store.activeTripId = settings.activeTripId
        syncTripActiveFlags(activeId: settings.activeTripId)
    }

    /// Aligns `Trip.isActive` with the restored `activeTripId` preference.
    private func syncTripActiveFlags(activeId: String?) {
        let allTrips = (try? modelContext.fetch(FetchDescriptor<Trip>())) ?? []
        for trip in allTrips {
            trip.isActive = (trip.id == activeId)
        }
        try? modelContext.save()
    }
}

// MARK: - Backup Codable Mirrors

/// UserDefaults settings included in JSON backup/restore.
struct BackupSettings: Codable {
    var currencyCode: String?
    var isDarkMode: Bool?
    var activeTripId: String?
    var budgetLimits: [String: Double]?
    var quickActions: [QuickAction]?
}

/// Single Codable container holding every model array for JSON backup/restore.
struct BackupBundle: Codable {
    var transactions: [CodableTransaction]
    var wallets: [CodableWallet]
    var categories: [CodableCategory]
    var trips: [CodableTrip]
    var goals: [CodableGoal]
    var subscriptions: [CodableSubscription]
    var recurringRules: [CodableRecurringRule]
    /// App preferences. Omitted in backups created before this field existed.
    var settings: BackupSettings?
}

struct CodableTransaction: Codable {
    var id: UUID
    var type: String
    var amount: Double
    var currencyCode: String
    var categoryId: String
    var walletId: String
    var note: String
    var tags: [String]
    var tripId: String?
    var date: Date
    var fromRecurringId: String?

    init(
        id: UUID,
        type: String,
        amount: Double,
        currencyCode: String,
        categoryId: String,
        walletId: String,
        note: String,
        tags: [String],
        tripId: String?,
        date: Date,
        fromRecurringId: String?
    ) {
        self.id = id
        self.type = type
        self.amount = amount
        self.currencyCode = currencyCode
        self.categoryId = categoryId
        self.walletId = walletId
        self.note = note
        self.tags = tags
        self.tripId = tripId
        self.date = date
        self.fromRecurringId = fromRecurringId
    }

    init(_ m: Transaction) {
        self.init(
            id: m.id,
            type: m.type,
            amount: m.amount,
            currencyCode: m.currencyCode,
            categoryId: m.categoryId,
            walletId: m.walletId,
            note: m.note,
            tags: m.tags,
            tripId: m.tripId,
            date: m.date,
            fromRecurringId: m.fromRecurringId
        )
    }

    func toModel() -> Transaction {
        Transaction(id: id, type: type, amount: amount, currencyCode: currencyCode,
                    categoryId: categoryId, walletId: walletId, note: note, tags: tags,
                    tripId: tripId, date: date, fromRecurringId: fromRecurringId)
    }
}

struct CodableWallet: Codable {
    var id: String, name: String, emoji: String, colorHex: String, isDefault: Bool
    init(id: String, name: String, emoji: String, colorHex: String, isDefault: Bool) {
        self.id = id; self.name = name; self.emoji = emoji; self.colorHex = colorHex; self.isDefault = isDefault
    }
    init(_ m: Wallet) { id = m.id; name = m.name; emoji = m.emoji; colorHex = m.colorHex; isDefault = m.isDefault }
    func toModel() -> Wallet { Wallet(id: id, name: name, emoji: emoji, colorHex: colorHex, isDefault: isDefault) }
}

struct CodableCategory: Codable {
    var id: String, label: String, emoji: String, colorHex: String, type: String, isDefault: Bool
    init(id: String, label: String, emoji: String, colorHex: String, type: String, isDefault: Bool) {
        self.id = id; self.label = label; self.emoji = emoji; self.colorHex = colorHex; self.type = type; self.isDefault = isDefault
    }
    init(_ m: AppCategory) { id = m.id; label = m.label; emoji = m.emoji; colorHex = m.colorHex; type = m.type; isDefault = m.isDefault }
    func toModel() -> AppCategory { AppCategory(id: id, label: label, emoji: emoji, colorHex: colorHex, type: type, isDefault: isDefault) }
}

struct CodableTrip: Codable {
    var id: String, name: String, budget: Double, isActive: Bool
    init(id: String, name: String, budget: Double, isActive: Bool) {
        self.id = id; self.name = name; self.budget = budget; self.isActive = isActive
    }
    init(_ m: Trip) { id = m.id; name = m.name; budget = m.budget; isActive = m.isActive }
    func toModel() -> Trip { Trip(id: id, name: name, budget: budget, isActive: isActive) }
}

struct CodableGoal: Codable {
    var id: String, name: String, target: Double, saved: Double, emoji: String
    init(id: String, name: String, target: Double, saved: Double, emoji: String) {
        self.id = id; self.name = name; self.target = target; self.saved = saved; self.emoji = emoji
    }
    init(_ m: SavingsGoal) { id = m.id; name = m.name; target = m.target; saved = m.saved; emoji = m.emoji }
    func toModel() -> SavingsGoal { SavingsGoal(id: id, name: name, target: target, saved: saved, emoji: emoji) }
}

struct CodableSubscription: Codable {
    var id: String, name: String, amount: Double, period: String, emoji: String
    init(id: String, name: String, amount: Double, period: String, emoji: String) {
        self.id = id; self.name = name; self.amount = amount; self.period = period; self.emoji = emoji
    }
    init(_ m: Subscription) { id = m.id; name = m.name; amount = m.amount; period = m.period; emoji = m.emoji }
    func toModel() -> Subscription { Subscription(id: id, name: name, amount: amount, period: period, emoji: emoji) }
}

struct CodableRecurringRule: Codable {
    var id: String, type: String, amount: Double, categoryId: String, walletId: String
    var note: String, frequency: String, startDate: Date, lastRun: Date
    init(
        id: String, type: String, amount: Double, categoryId: String, walletId: String,
        note: String, frequency: String, startDate: Date, lastRun: Date
    ) {
        self.id = id; self.type = type; self.amount = amount; self.categoryId = categoryId; self.walletId = walletId
        self.note = note; self.frequency = frequency; self.startDate = startDate; self.lastRun = lastRun
    }
    init(_ m: RecurringRule) {
        id = m.id; type = m.type; amount = m.amount; categoryId = m.categoryId; walletId = m.walletId
        note = m.note; frequency = m.frequency; startDate = m.startDate; lastRun = m.lastRun
    }
    func toModel() -> RecurringRule {
        RecurringRule(id: id, type: type, amount: amount, categoryId: categoryId, walletId: walletId,
                      note: note, frequency: frequency, startDate: startDate, lastRun: lastRun)
    }
}

#Preview {
    SettingsView()
        .environment(DataStore())
        .modelContainer(DataStore.modelContainer)
}
