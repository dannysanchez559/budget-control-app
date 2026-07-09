//
//  WalletManagerView.swift
//  Budget Control
//
//  Sheet for viewing, adding, editing, and deleting wallets. Opened from Home
//  → Accounts → Edit. Default seed wallets can be renamed but not deleted.
//

import SwiftUI
import SwiftData

struct WalletManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(DataStore.self) private var store

    @Query(sort: \Wallet.name) private var wallets: [Wallet]
    @Query private var transactions: [Transaction]

    @State private var editingWallet: Wallet?
    @State private var showingNewWallet = false
    @State private var pendingDelete: Wallet?

    private var deleteBinding: Binding<Bool> {
        Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(Array(wallets.enumerated()), id: \.element.id) { index, wallet in
                        Button {
                            editingWallet = wallet
                        } label: {
                            walletRow(wallet, index: index)
                        }
                        .buttonStyle(.plain)
                    }
                } footer: {
                    Text("Tap a wallet to edit its name and icon. Default wallets cannot be deleted.")
                        .font(.appSans(AppTheme.Typography.fontLabel))
                        .foregroundStyle(AppTheme.Colors.textMuted)
                }
                .listRowBackground(AppTheme.Colors.surface)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppTheme.Colors.background)
            .navigationTitle("Accounts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewWallet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .tint(AppTheme.Colors.accent)
                }
            }
            .sheet(item: $editingWallet) { wallet in
                WalletFormView(wallet: wallet, onDelete: {
                    pendingDelete = wallet
                    editingWallet = nil
                })
            }
            .sheet(isPresented: $showingNewWallet) {
                WalletFormView(wallet: nil, onDelete: nil)
            }
            .confirmationDialog(
                "Delete this wallet?",
                isPresented: deleteBinding,
                presenting: pendingDelete
            ) { wallet in
                Button("Delete", role: .destructive) { delete(wallet) }
                Button("Cancel", role: .cancel) {}
            } message: { wallet in
                let count = transactions.filter { $0.walletId == wallet.id }.count
                if count > 0 {
                    Text("This wallet has \(count) transaction\(count == 1 ? "" : "s"). Historical records will keep the wallet reference.")
                } else {
                    Text("This can't be undone.")
                }
            }
        }
    }

    private func walletRow(_ wallet: Wallet, index: Int) -> some View {
        let pastel = IconMap.pastel(forIndex: index)
        let symbol = IconMap.symbol(forWallet: wallet.id, storedIcon: wallet.emoji)
        let balance = transactions.balance(forWallet: wallet.id)

        return HStack(spacing: AppTheme.Spacing.sm) {
            IconBadge(symbol: symbol, style: pastel, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(wallet.name)
                    .font(.appSans(AppTheme.Typography.fontBody, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Text(store.formatAmount(balance))
                    .font(.appSans(AppTheme.Typography.fontLabel, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.textMuted)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textMuted.opacity(0.5))
        }
    }

    private func delete(_ wallet: Wallet) {
        guard !wallet.isDefault else { return }
        modelContext.delete(wallet)
        try? modelContext.save()
        pendingDelete = nil
        editingWallet = nil
    }
}

// MARK: - Wallet Form

private struct WalletFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var wallet: Wallet?
    var onDelete: (() -> Void)?

    @State private var name = ""
    @State private var symbol = "banknote.fill"

    private let symbolChoices = [
        "banknote.fill", "creditcard.fill", "building.columns.fill",
        "wallet.pass.fill", "dollarsign.circle.fill", "bitcoinsign.circle.fill",
        "iphone", "gift.fill", "briefcase.fill", "star.fill", "leaf.fill", "globe",
    ]

    private var isNew: Bool { wallet == nil }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        VStack(spacing: AppTheme.Spacing.md) {
                            HStack {
                                Text("Name")
                                    .font(.appSans(15))
                                    .foregroundStyle(AppTheme.Colors.textPrimary)
                                Spacer()
                                TextField("Wallet name", text: $name)
                                    .multilineTextAlignment(.trailing)
                                    .font(.appSans(15))
                            }
                        }
                        .cardStyle()

                        iconPicker

                        if !isNew, wallet?.isDefault == false, onDelete != nil {
                            Button(role: .destructive, action: { onDelete?() }) {
                                Text("Delete Wallet")
                                    .font(.appSans(15, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, AppTheme.Spacing.sm)
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                }
            }
            .navigationTitle(isNew ? "New Wallet" : "Edit Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isNew ? "Create" : "Save", action: save)
                        .fontWeight(.semibold)
                        .foregroundStyle(canSave ? AppTheme.Colors.accent : AppTheme.Colors.textMuted)
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: loadState)
        }
    }

    private var iconPicker: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Icon")
                .font(.appSans(AppTheme.Typography.fontLabel, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textMuted)
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: AppTheme.Spacing.sm), count: 4),
                spacing: AppTheme.Spacing.sm
            ) {
                ForEach(symbolChoices, id: \.self) { choice in
                    let isSelected = choice == symbol
                    Button { symbol = choice } label: {
                        IconBadge(symbol: choice, style: .sky, size: 36)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .background(isSelected ? AppTheme.Colors.accent.opacity(0.12) : AppTheme.Colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                                    .stroke(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.border, lineWidth: isSelected ? 2 : 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func loadState() {
        if let wallet {
            name = wallet.name
            let stored = wallet.emoji
            symbol = !stored.isEmpty && stored.allSatisfy(\.isASCII)
                ? stored
                : IconMap.symbol(forWallet: wallet.id)
        }
    }

    private func save() {
        guard canSave else { return }
        let trimmed = name.trimmingCharacters(in: .whitespaces)

        if let wallet {
            wallet.name = trimmed
            wallet.emoji = symbol
        } else {
            let newWallet = Wallet(
                id: "wallet-\(UUID().uuidString.prefix(8))",
                name: trimmed,
                emoji: symbol,
                colorHex: "#7AC9A6",
                isDefault: false
            )
            modelContext.insert(newWallet)
        }

        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    WalletManagerView()
        .environment(DataStore())
        .modelContainer(DataStore.modelContainer)
}
