//
//  CardPaymentView.swift
//  Budget Control
//
//  Dedicated "pay down a credit card" sheet. Unlike the normal Add
//  Transaction flow, the amount is capped at the wallet's outstanding
//  balance — a payment can never push a credit card into a positive
//  balance. Writes a `type: "income"` transaction tagged `isCardPayment`
//  so it still settles the wallet's balance but is excluded from the
//  monthly Income total on Home.
//

import SwiftUI
import SwiftData

struct CardPaymentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(DataStore.self) private var store

    @Query private var transactions: [Transaction]

    var wallet: Wallet

    @State private var amountText: String = ""

    private var outstandingBalance: Double {
        max(0, -transactions.balance(forWallet: wallet.id))
    }

    private var amountValue: Double {
        Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private var canSave: Bool {
        amountValue > 0 && amountValue <= outstandingBalance + 0.0001
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()

                if outstandingBalance <= 0 {
                    noBalanceState
                } else {
                    ScrollView {
                        VStack(spacing: AppTheme.Spacing.lg) {
                            header
                            amountField
                            payInFullButton
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, AppTheme.Spacing.md)
                    }
                }
            }
            .navigationTitle("Pay Down \(wallet.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                if outstandingBalance > 0 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save", action: save)
                            .fontWeight(.semibold)
                            .foregroundStyle(canSave ? AppTheme.Colors.income : AppTheme.Colors.textMuted)
                            .disabled(!canSave)
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            IconBadge(symbol: IconMap.symbol(forWallet: wallet.id, storedIcon: wallet.emoji), style: .sky, size: 44)
            Text("You owe")
                .font(.appSans(13, weight: .medium))
                .foregroundStyle(AppTheme.Colors.textMuted)
            Text(store.formatAmount(outstandingBalance))
                .font(.appSans(28, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppTheme.Spacing.sm)
    }

    // MARK: - Amount

    private var amountField: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            sectionLabel("Payment amount")
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.sm) {
                Text(DataStore.currencyInfo(for: store.currencyCode).symbol)
                    .font(.appSerif(30, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.textMuted)
                TextField("0", text: $amountText)
                    .font(.appSerif(44, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.income)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, AppTheme.Spacing.xs)

            if amountValue > outstandingBalance {
                Text("Can't pay more than the outstanding balance.")
                    .font(.appSans(12, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.danger)
            }
        }
        .cardStyle()
    }

    private var payInFullButton: some View {
        Button {
            amountText = String(format: "%g", outstandingBalance)
        } label: {
            Text("Pay in Full — \(store.formatAmount(outstandingBalance))")
                .font(.appSans(15, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.income)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppTheme.Colors.income.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - No Balance State

    private var noBalanceState: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.Colors.income)
            Text("No balance due")
                .font(.appSans(16, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Text("\(wallet.name) is fully paid off.")
                .font(.appSans(13))
                .foregroundStyle(AppTheme.Colors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.appSans(12, weight: .semibold))
            .foregroundStyle(AppTheme.Colors.textMuted)
    }

    private func save() {
        guard canSave else { return }
        let tx = Transaction(
            type: "income",
            amount: amountValue,
            currencyCode: store.currencyCode,
            categoryId: "cat-card-payment",
            walletId: wallet.id,
            note: "Card payment",
            date: .now,
            isCardPayment: true
        )
        modelContext.insert(tx)
        try? modelContext.save()
        HapticManager.impact()
        dismiss()
    }
}

#Preview {
    CardPaymentView(wallet: Wallet(id: "wallet-card", name: "Card", emoji: "💳", isCreditCard: true))
        .environment(DataStore())
        .modelContainer(DataStore.modelContainer)
}
