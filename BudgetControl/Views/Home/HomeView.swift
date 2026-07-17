//
//  HomeView.swift
//  Budget Control
//
//  Dashboard — the most visible screen. Professional pastel layout: greeting
//  header with settings control, a gradient hero balance card (this month, income/expense
//  split), a horizontal Accounts strip of pastel AccountCards (all-time wallet
//  balances), a pastel BudgetCard grid, optional quick-add pills, and recent
//  transactions (last 3 days) grouped into white cards. All data is read from
//  SwiftData and derived in place.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query(sort: \Wallet.name) private var wallets: [Wallet]
    @Query private var categories: [AppCategory]
    @Query private var trips: [Trip]

    @State private var editingTransaction: Transaction?
    @State private var showingSettings = false
    @State private var showingBudgetManager = false
    @State private var showingSearch = false
    @State private var showingAllTransactions = false
    @State private var showingWalletManager = false
    @State private var payingWallet: Wallet?
    @State private var pendingDelete: Transaction?

    // UserDefaults-backed settings are not @Observable, so mirror them in
    // local state (loaded in onAppear, written through on mutation) to keep
    // the view in sync when they change.
    @State private var currencyCode = "USD"
    @State private var activeTripId: String?
    @State private var quickActions: [QuickAction] = []

    /// Vertical gap between the major sections of the dashboard.
    private let sectionSpacing: CGFloat = 28
    /// Horizontal inset for content that runs to the screen edge.
    private let edgePadding: CGFloat = 20

    // Fast lookups for resolving a transaction's category/wallet in rows.
    private var categoryById: [String: AppCategory] {
        Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
    }
    private var walletById: [String: Wallet] {
        Dictionary(uniqueKeysWithValues: wallets.map { ($0.id, $0) })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: sectionSpacing) {
                    header
                    if let trip = activeTrip { tripBanner(trip) }
                    balanceCard
                    walletsSection
                    budgetSection
                    if !quickActions.isEmpty { quickAddSection }
                    recentSection
                }
                .padding(.top, AppTheme.Spacing.md)
                .padding(.bottom, AppTheme.Spacing.sm)
            }
            .background(AppTheme.Colors.background)
            .toolbar(.hidden, for: .navigationBar)
            .tabShellBottomInset()
            .sheet(item: $editingTransaction) { tx in
                AddTransactionView(editing: tx)
            }
            .sheet(isPresented: $showingSettings, onDismiss: loadSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingBudgetManager, onDismiss: loadSettings) {
                BudgetManagerView()
            }
            .sheet(isPresented: $showingSearch) {
                SearchView()
            }
            .sheet(isPresented: $showingAllTransactions) {
                AllTransactionsView()
            }
            .sheet(isPresented: $showingWalletManager) {
                WalletManagerView()
            }
            .sheet(item: $payingWallet) { wallet in
                CardPaymentView(wallet: wallet)
            }
            .confirmationDialog(
                "Delete this transaction?",
                isPresented: Binding(
                    get: { pendingDelete != nil },
                    set: { if !$0 { pendingDelete = nil } }
                ),
                presenting: pendingDelete
            ) { tx in
                Button("Delete", role: .destructive) { delete(tx) }
                Button("Cancel", role: .cancel) {}
            } message: { _ in
                Text("This can't be undone.")
            }
            .onAppear(perform: loadSettings)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.appSans(AppTheme.Typography.fontCaption, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.textMuted)
                Text(monthTitle)
                    .font(.appSans(AppTheme.Typography.fontTitle, weight: .bold))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }
            Spacer()
            HStack(spacing: AppTheme.Spacing.md) {
                Button {
                    showingSearch = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(AppTheme.Colors.textMuted)
                }
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(AppTheme.Colors.accent)
                        .clipShape(Circle())
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, edgePadding)
    }

    private var monthTitle: String {
        _ = store.calendarPeriodId
        return Date.now.formatted(.dateTime.month(.wide).year())
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date.now) {
        case 5...11: return "Good morning"
        case 12...16: return "Good afternoon"
        case 17...20: return "Good evening"
        default: return "Good night"
        }
    }

    // MARK: - Active Trip Banner

    private var activeTrip: Trip? {
        guard let id = activeTripId else { return nil }
        return trips.first { $0.id == id }
    }

    private func tripBanner(_ trip: Trip) -> some View {
        Button {
            activeTripId = nil
            store.activeTripId = nil
            trip.isActive = false
            try? modelContext.save()
        } label: {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "airplane")
                VStack(alignment: .leading, spacing: 1) {
                    Text("Active trip")
                        .font(.appSans(11, weight: .semibold))
                        .opacity(0.85)
                    Text(trip.name)
                        .font(.appSans(15, weight: .semibold))
                }
                Spacer()
                Text("Tap to end")
                    .font(.appSans(12, weight: .medium))
                    .opacity(0.85)
            }
            .foregroundStyle(.white)
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.teal)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, edgePadding)
    }

    // MARK: - Hero Balance Card

    private var monthTransactions: [Transaction] {
        _ = store.calendarPeriodId
        return transactions.inMonth()
    }

    private var lastMonthTransactions: [Transaction] {
        _ = store.calendarPeriodId
        let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
        return transactions.inMonth(of: lastMonth)
    }

    /// Month-over-month change in expenses. `nil` when there's no prior-month
    /// spending to compare against. `isUp` means spending increased.
    private var spendingChange: (percent: Double, isUp: Bool)? {
        let current = monthTransactions.expenseTotal
        let previous = lastMonthTransactions.expenseTotal
        guard previous > 0 else { return nil }
        let pct = (current - previous) / previous * 100
        return (abs(pct), pct >= 0)
    }

    private var balanceCard: some View {
        let income = monthTransactions.incomeTotal
        let expense = monthTransactions.expenseTotal
        let net = income - expense

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("Working balance")
                    .font(.appSans(AppTheme.Typography.fontCaption, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                currencyButton
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(store.formatAmount(net))
                    .font(.appSans(AppTheme.Typography.fontBalance, weight: .thin))
                    .tracking(AppTheme.Typography.trackingTight)
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: 0.3), value: net)
                Text(monthTitle)
                    .font(.appSans(AppTheme.Typography.fontCaption, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }

            HStack(spacing: AppTheme.Spacing.sm) {
                heroInnerCard(title: "Income", amount: income)
                heroInnerCard(title: "Expenses", amount: expense)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Colors.heroGradient)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: AppTheme.Colors.heroCard.opacity(0.35), radius: 16, x: 0, y: 8)
        .padding(.horizontal, edgePadding)
    }

    private func heroInnerCard(title: String, amount: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.appSans(AppTheme.Typography.fontCaption, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
            Text(store.formatAmount(amount))
                .font(.appSans(AppTheme.Typography.fontCardNumber, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
    }

    private var currencyButton: some View {
        Button(action: cycleCurrency) {
            HStack(spacing: 4) {
                Text(currencyCode)
                    .font(.appSans(13, weight: .semibold))
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.20))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Accounts

    private var walletsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            sectionHeader("Accounts") {
                Button("Edit") {
                    showingWalletManager = true
                }
                .font(.appSans(AppTheme.Typography.fontLabel, weight: .medium))
                .foregroundStyle(AppTheme.Colors.accent)
            }
            .padding(.horizontal, edgePadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(wallets.enumerated()), id: \.element.id) { index, wallet in
                        if wallet.isCreditCard {
                            Button {
                                payingWallet = wallet
                            } label: {
                                AccountCard(
                                    wallet: wallet,
                                    balance: transactions.balance(forWallet: wallet.id),
                                    index: index
                                )
                            }
                            .buttonStyle(.plain)
                        } else {
                            AccountCard(
                                wallet: wallet,
                                balance: transactions.balance(forWallet: wallet.id),
                                index: index
                            )
                        }
                    }
                }
                .padding(.horizontal, edgePadding)
            }
        }
    }

    // MARK: - Budgets

    /// One tile in the Home budgets strip — set limits first, unset after (A→Z).
    private struct BudgetStripItem: Identifiable {
        let category: AppCategory
        let spent: Double
        let limit: Double?
        var id: String { category.id }
    }

    private var budgetStripItems: [BudgetStripItem] {
        let expense = categories
            .filter { $0.type == "expense" }
            .sorted { $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending }

        func monthSpent(for categoryId: String) -> Double {
            monthTransactions
                .filter { $0.categoryId == categoryId && $0.type == "expense" }
                .reduce(0) { $0 + $1.amount }
        }

        var withLimit: [BudgetStripItem] = []
        var withoutLimit: [BudgetStripItem] = []

        for category in expense {
            let spent = monthSpent(for: category.id)
            if let limit = store.budgetLimits[category.id], limit > 0 {
                withLimit.append(BudgetStripItem(category: category, spent: spent, limit: limit))
            } else {
                withoutLimit.append(BudgetStripItem(category: category, spent: spent, limit: nil))
            }
        }

        return withLimit + withoutLimit
    }

    private var budgetSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            sectionHeader("Your budgets") {
                Button("Manage") {
                    showingBudgetManager = true
                }
                .font(.appSans(AppTheme.Typography.fontLabel, weight: .medium))
                .foregroundStyle(AppTheme.Colors.accent)
            }
            .padding(.horizontal, edgePadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(budgetStripItems.enumerated()), id: \.element.id) { index, item in
                        BudgetCard(
                            category: item.category,
                            spent: item.spent,
                            limit: item.limit,
                            index: index
                        )
                    }
                }
                .padding(.horizontal, edgePadding)
            }
        }
    }

    // MARK: - Quick Add

    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            sectionHeader("Quick Add") { EmptyView() }
                .padding(.horizontal, edgePadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(quickActions.enumerated()), id: \.element.id) { index, action in
                        quickAddChip(action, index: index)
                    }
                }
                .padding(.horizontal, edgePadding)
            }
        }
    }

    private func quickAddChip(_ action: QuickAction, index: Int) -> some View {
        let pastel = IconMap.pastel(forIndex: index)
        let symbol = IconMap.symbol(forCategory: action.categoryId)
        return Button { runQuickAction(action) } label: {
            HStack(spacing: AppTheme.Spacing.sm) {
                IconBadge(symbol: symbol, style: pastel, size: 28)
                Text(store.formatAmount(action.amount))
                    .font(.appSans(14, weight: .semibold))
                    .foregroundStyle(pastel.text)
            }
            .padding(.leading, 8)
            .padding(.trailing, 14)
            .padding(.vertical, 8)
            .background(pastel.fill)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) { removeQuickAction(action) } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }

    // MARK: - Recent Transactions

    /// Day-groups for transactions in the last 3 calendar days (today + 2).
    private var recentGroups: [DayGroup] {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -2, to: calendar.startOfDay(for: .now)) ?? .now
        let recent = transactions.filter { $0.date >= cutoff }
        return TransactionGrouping.byDay(recent)
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            sectionHeader("Recent") {
                Button("See all") {
                    showingAllTransactions = true
                }
                .font(.appSans(AppTheme.Typography.fontLabel, weight: .medium))
                .foregroundStyle(AppTheme.Colors.accent)
            }

            if recentGroups.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(recentGroups) { group in
                        Section {
                            ForEach(group.transactions) { tx in
                                recentRow(tx)
                            }
                        } header: {
                            Text(group.label)
                                .font(.appSans(AppTheme.Typography.fontLabel, weight: .semibold))
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                                .textCase(nil)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollDisabled(true)
                .scrollContentBackground(.hidden)
                .frame(height: recentListHeight)
            }
        }
        .padding(.horizontal, edgePadding)
    }

    /// Approximate height for the non-scrolling recent-transactions list.
    private var recentListHeight: CGFloat {
        let rowHeight: CGFloat = 72
        let headerHeight: CGFloat = 28
        let count = recentGroups.reduce(0) { $0 + $1.transactions.count }
        return CGFloat(count) * rowHeight + CGFloat(recentGroups.count) * headerHeight
    }

    private func recentRow(_ tx: Transaction) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Button { editingTransaction = tx } label: {
                TransactionRowView(
                    transaction: tx,
                    category: categoryById[tx.categoryId],
                    wallet: walletById[tx.walletId]
                )
            }
            .buttonStyle(.plain)

            Button { saveAsQuickAction(tx) } label: {
                Image(systemName: "repeat")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.textMuted)
            }
            .buttonStyle(.plain)
            .disabled(quickActions.count >= 6)
            .opacity(quickActions.count >= 6 ? 0.3 : 1)
        }
        .listRowBackground(AppTheme.Colors.surface)
        .listRowInsets(EdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) { pendingDelete = tx } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "wallet.bifold")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.Colors.textMuted.opacity(0.5))
            Text("No entries yet")
                .font(.appSans(16, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textMuted)
            Text("Tap + to add your first record")
                .font(.appSans(13))
                .foregroundStyle(AppTheme.Colors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Section Header Helper

    private func sectionHeader<Trailing: View>(
        _ title: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack {
            Text(title)
                .font(.appSans(17, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Spacer()
            trailing()
        }
    }

    // MARK: - Actions

    private func loadSettings() {
        currencyCode = store.currencyCode
        activeTripId = store.activeTripId
        quickActions = store.quickActions
    }

    private func cycleCurrency() {
        let codes = DataStore.currencies.map(\.code)
        let index = codes.firstIndex(of: currencyCode) ?? 0
        let next = codes[(index + 1) % codes.count]
        currencyCode = next
        store.currencyCode = next
    }

    private func delete(_ tx: Transaction) {
        withAnimation {
            modelContext.delete(tx)
            try? modelContext.save()
        }
    }

    private func saveAsQuickAction(_ tx: Transaction) {
        guard quickActions.count < 6 else { return }
        let action = QuickAction(
            type: tx.type,
            amount: tx.amount,
            categoryId: tx.categoryId,
            walletId: tx.walletId,
            note: tx.note
        )
        var updated = quickActions
        updated.append(action)
        quickActions = updated
        store.quickActions = updated
    }

    private func removeQuickAction(_ action: QuickAction) {
        let updated = quickActions.filter { $0.id != action.id }
        quickActions = updated
        store.quickActions = updated
    }

    private func runQuickAction(_ action: QuickAction) {
        // Auto-tag to the active trip for expenses only.
        let tripId = (action.type == "expense") ? activeTripId : nil
        let tx = Transaction(
            type: action.type,
            amount: action.amount,
            currencyCode: store.currencyCode,
            categoryId: action.categoryId,
            walletId: action.walletId,
            note: action.note,
            tripId: tripId,
            date: .now
        )
        modelContext.insert(tx)
        try? modelContext.save()
    }
}

#Preview {
    HomeView()
        .environment(DataStore())
        .modelContainer(DataStore.modelContainer)
}
