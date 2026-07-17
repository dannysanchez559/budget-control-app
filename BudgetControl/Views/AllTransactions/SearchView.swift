//
//  SearchView.swift
//  Budget Control
//
//  A search sheet over the full transaction history. The field auto-focuses on
//  appear. A query matches against note, category label, wallet name, the
//  amount string, or tags. Results render with the shared TransactionRowView;
//  tapping one opens it for editing.
//

import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query private var wallets: [Wallet]
    @Query private var categories: [AppCategory]

    @State private var query = ""
    @State private var editingTransaction: Transaction?
    @FocusState private var searchFocused: Bool

    private var categoryById: [String: AppCategory] {
        Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
    }
    private var walletById: [String: Wallet] {
        Dictionary(uniqueKeysWithValues: wallets.map { ($0.id, $0) })
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var results: [Transaction] {
        guard !trimmedQuery.isEmpty else { return [] }
        return transactions.filter { tx in
            let category = categoryById[tx.categoryId]
            let wallet = walletById[tx.walletId]
            let amountString = String(format: "%.2f", tx.amount)
            let haystack = [
                tx.note,
                category?.label ?? "",
                wallet?.name ?? "",
                amountString,
                tx.tags.joined(separator: " ")
            ]
            .joined(separator: " ")
            .lowercased()
            return haystack.contains(trimmedQuery)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                content
            }
            .background(AppTheme.Colors.background)
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .tint(AppTheme.Colors.accent)
                }
            }
            .sheet(item: $editingTransaction) { tx in
                AddTransactionView(editing: tx)
            }
            .onAppear { searchFocused = true }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.Colors.textMuted)
            TextField("Search transactions", text: $query)
                .font(.appSans(AppTheme.Typography.fontBody))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .focused($searchFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.Colors.textMuted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm + 2)
        .background(AppTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
        .padding(AppTheme.Spacing.md)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if trimmedQuery.isEmpty {
            placeholder(
                icon: "magnifyingglass",
                pastel: .sky,
                title: "Search your transactions",
                subtitle: "Find by note, category, wallet, amount, or tag"
            )
        } else if results.isEmpty {
            placeholder(
                icon: "doc.text.magnifyingglass",
                pastel: .rose,
                title: "No results",
                subtitle: "Nothing matches “\(query)”"
            )
        } else {
            resultsList
        }
    }

    private var resultsList: some View {
        List {
            ForEach(results) { tx in
                TransactionRowView(
                    transaction: tx,
                    category: categoryById[tx.categoryId],
                    wallet: walletById[tx.walletId]
                )
                .contentShape(Rectangle())
                .onTapGesture { editingTransaction = tx }
                .listRowBackground(AppTheme.Colors.surface)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private func placeholder(icon: String, pastel: PastelStyle, title: String, subtitle: String) -> some View {
        EmptyStateView(symbol: icon, pastel: pastel, title: title, subtitle: subtitle)
            .padding(.horizontal, AppTheme.Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SearchView()
        .environment(DataStore())
        .modelContainer(DataStore.modelContainer)
}
