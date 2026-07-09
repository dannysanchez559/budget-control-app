//
//  AllTransactionsView.swift
//  Budget Control
//
//  Complete transaction history, grouped by day. Tap a row to edit; swipe to
//  edit (leading) or delete (trailing, confirmed); tap the repeat icon to save
//  a row as a quick action. The toolbar offers search and a sort toggle
//  (date ↓ / date ↑ / amount ↓).
//

import SwiftUI
import SwiftData

struct AllTransactionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(DataStore.self) private var store

    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query private var wallets: [Wallet]
    @Query private var categories: [AppCategory]

    @State private var editingTransaction: Transaction?
    @State private var pendingDelete: Transaction?
    @State private var showingSearch = false
    @State private var sortMode: SortMode = .dateDescending
    @State private var isSelecting = false
    @State private var selectedIds: Set<UUID> = []
    @State private var showingBulkDeleteConfirm = false

    // Mirrors UserDefaults so the repeat button can disable at the 6 cap.
    @State private var quickActions: [QuickAction] = []

    private var categoryById: [String: AppCategory] {
        Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
    }
    private var walletById: [String: Wallet] {
        Dictionary(uniqueKeysWithValues: wallets.map { ($0.id, $0) })
    }

    // Day-grouped sections for the two date sort modes.
    private var groups: [DayGroup] {
        switch sortMode {
        case .dateDescending: return TransactionGrouping.byDay(transactions)
        case .dateAscending:  return TransactionGrouping.byDay(transactions, ascending: true)
        case .amountDescending: return []
        }
    }

    // Flat list for the amount sort mode (largest first).
    private var amountSorted: [Transaction] {
        transactions.sorted { $0.amount > $1.amount }
    }

    private var deleteBinding: Binding<Bool> {
        Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })
    }

    var body: some View {
        NavigationStack {
            Group {
                if transactions.isEmpty {
                    emptyState
                } else {
                    transactionList
                }
            }
            .background(AppTheme.Colors.background)
            .navigationTitle("All")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .tabShellBottomInset()
            .sheet(item: $editingTransaction) { tx in
                AddTransactionView(editing: tx)
            }
            .sheet(isPresented: $showingSearch) {
                SearchView()
            }
            .confirmationDialog(
                "Delete this transaction?",
                isPresented: deleteBinding,
                presenting: pendingDelete
            ) { tx in
                Button("Delete", role: .destructive) { delete(tx) }
                Button("Cancel", role: .cancel) {}
            } message: { _ in
                Text("This can't be undone.")
            }
            .confirmationDialog(
                "Delete \(selectedIds.count) transaction\(selectedIds.count == 1 ? "" : "s")?",
                isPresented: $showingBulkDeleteConfirm
            ) {
                Button("Delete", role: .destructive) { deleteSelected() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This can't be undone.")
            }
            .onAppear { quickActions = store.quickActions }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("All")
                .font(.appSans(AppTheme.Typography.fontBody, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textPrimary)
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            if !transactions.isEmpty {
                Button(isSelecting ? "Done" : "Select") {
                    isSelecting.toggle()
                    if !isSelecting { selectedIds.removeAll() }
                }
                .font(.appSans(15, weight: .semibold))
                .tint(AppTheme.Colors.accent)
            }

            if isSelecting, !selectedIds.isEmpty {
                Button("Delete") { showingBulkDeleteConfirm = true }
                    .font(.appSans(15, weight: .semibold))
                    .tint(AppTheme.Colors.danger)
            }

            if !isSelecting {
                Button { sortMode = sortMode.next } label: {
                    Image(systemName: sortMode.iconName)
                }
                .tint(AppTheme.Colors.accent)

                Button { showingSearch = true } label: {
                    Image(systemName: "magnifyingglass")
                }
                .tint(AppTheme.Colors.accent)
            }
        }
    }

    // MARK: - List

    private var transactionList: some View {
        List {
            if sortMode == .amountDescending {
                Section {
                    ForEach(amountSorted) { row($0) }
                }
            } else {
                ForEach(groups) { group in
                    Section {
                        ForEach(group.transactions) { row($0) }
                    } header: {
                        Text(group.label)
                            .font(.appSans(AppTheme.Typography.fontLabel, weight: .semibold))
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private func row(_ tx: Transaction) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            if isSelecting {
                Image(systemName: selectedIds.contains(tx.id) ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(selectedIds.contains(tx.id) ? AppTheme.Colors.accent : AppTheme.Colors.textMuted)
            }

            TransactionRowView(
                transaction: tx,
                category: categoryById[tx.categoryId],
                wallet: walletById[tx.walletId]
            )

            if !isSelecting {
                Button { saveAsQuickAction(tx) } label: {
                    Image(systemName: "repeat")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.Colors.textMuted)
                }
                .buttonStyle(.plain)
                .disabled(quickActions.count >= 6)
                .opacity(quickActions.count >= 6 ? 0.3 : 1)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isSelecting {
                toggleSelection(tx)
            } else {
                editingTransaction = tx
            }
        }
        .listRowBackground(AppTheme.Colors.surface)
        .listRowSeparatorTint(AppTheme.Colors.borderAlt)
        // Inset the divider to start at the transaction text, not under the
        // 44pt icon badge (badge width + the row's internal spacing).
        .alignmentGuide(.listRowSeparatorLeading) { _ in
            (isSelecting ? 22 + AppTheme.Spacing.sm : 0) + 44 + AppTheme.Spacing.md
        }
        .transition(.asymmetric(insertion: .push(from: .bottom), removal: .opacity))
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            if !isSelecting {
                Button { editingTransaction = tx } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(AppTheme.Colors.accent)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if !isSelecting {
                Button(role: .destructive) { pendingDelete = tx } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.Colors.textMuted.opacity(0.5))
            Text("No transactions yet")
                .font(.appSerif(16))
                .foregroundStyle(AppTheme.Colors.textMuted)
            Text("Tap + to add your first record")
                .font(.appSans(13))
                .foregroundStyle(AppTheme.Colors.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func delete(_ tx: Transaction) {
        withAnimation {
            modelContext.delete(tx)
            try? modelContext.save()
            selectedIds.remove(tx.id)
        }
    }

    private func toggleSelection(_ tx: Transaction) {
        if selectedIds.contains(tx.id) {
            selectedIds.remove(tx.id)
        } else {
            selectedIds.insert(tx.id)
        }
    }

    private func deleteSelected() {
        withAnimation {
            for tx in transactions where selectedIds.contains(tx.id) {
                modelContext.delete(tx)
            }
            try? modelContext.save()
            selectedIds.removeAll()
            isSelecting = false
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
        // Cap at 6, silently dropping the oldest if over the limit.
        if updated.count > 6 { updated.removeFirst(updated.count - 6) }
        quickActions = updated
        store.quickActions = updated
    }
}

// MARK: - Sort Mode

extension AllTransactionsView {
    enum SortMode: CaseIterable {
        case dateDescending, dateAscending, amountDescending

        var next: SortMode {
            let all = Self.allCases
            let index = all.firstIndex(of: self) ?? 0
            return all[(index + 1) % all.count]
        }

        var iconName: String {
            switch self {
            case .dateDescending:   return "arrow.down.circle"
            case .dateAscending:    return "arrow.up.circle"
            case .amountDescending: return "dollarsign.circle"
            }
        }
    }
}

#Preview {
    AllTransactionsView()
        .environment(DataStore())
        .modelContainer(DataStore.modelContainer)
}
