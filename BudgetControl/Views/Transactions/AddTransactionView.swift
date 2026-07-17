//
//  AddTransactionView.swift
//  Budget Control
//
//  Add / Edit transaction sheet — the most-used flow in the app.
//  Type toggle (color-themed), large serif amount field, wallet chip row,
//  4-column category grid, date picker, optional note and tags.
//  Writes to SwiftData. If a trip is active and the type is Expense, the
//  transaction is auto-tagged with that trip id.
//
//  Receives an optional `editing` Transaction: nil creates a new record,
//  non-nil edits the existing one in place.
//

import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(DataStore.self) private var store

    /// Pass an existing transaction to edit it; nil creates a new one.
    var editing: Transaction?
    /// Pre-fill the date on new transactions (e.g. Calendar tab selected day).
    var initialDate: Date?

    init(editing: Transaction? = nil, initialDate: Date? = nil) {
        self.editing = editing
        self.initialDate = initialDate

        if let tx = editing {
            _type = State(initialValue: tx.type)
            _amountText = State(initialValue: tx.amount == 0 ? "" : String(format: "%g", tx.amount))
            _walletId = State(initialValue: tx.walletId)
            _categoryId = State(initialValue: tx.categoryId)
            _date = State(initialValue: tx.date)
            _note = State(initialValue: tx.note)
            _tagsText = State(initialValue: tx.tags.joined(separator: ", "))
        } else if let initialDate {
            _date = State(initialValue: Calendar.current.startOfDay(for: initialDate))
        }
    }

    @Query(sort: \Wallet.name) private var wallets: [Wallet]
    @Query(sort: \AppCategory.label) private var categories: [AppCategory]
    @Query private var allTransactions: [Transaction]

    @State private var type: String = "expense"
    @State private var amountText: String = ""
    @State private var walletId: String = ""
    @State private var categoryId: String = ""
    @State private var date: Date = .now
    @State private var note: String = ""
    @State private var tagsText: String = ""
    @State private var showingAddCategory = false

    private var amountValue: Double {
        Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }
    private var canSave: Bool { amountValue > 0 && !walletId.isEmpty && !categoryId.isEmpty }
    private var isEditing: Bool { editing != nil }

    private var visibleCategories: [AppCategory] {
        categories.filter { $0.type == type && $0.id != "cat-card-payment" }
    }

    /// Credit-card wallets can't receive normal "Income" entries — payments
    /// against them go through the dedicated `CardPaymentView` flow instead,
    /// which enforces the no-overpay cap. When editing an existing
    /// transaction, the already-selected wallet is kept visible even if it's
    /// a credit card, so opening a past card payment never silently clears
    /// its wallet. New transactions get no such exception, even if a credit
    /// card wallet happens to be the pre-selected default.
    private var visibleWallets: [Wallet] {
        guard type == "income" else { return wallets }
        return wallets.filter { !$0.isCreditCard || (isEditing && $0.id == walletId) }
    }

    /// Active accent shifts with the selected transaction type.
    private var accent: Color {
        type == "income" ? AppTheme.Colors.income : AppTheme.Colors.expense
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        typeToggle
                        amountField
                        walletSection
                        categorySection
                        detailsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, AppTheme.Spacing.md)
                }
            }
            .navigationTitle(isEditing ? "Edit Transaction" : "New Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditing ? "Save Changes" : "Save", action: save)
                        .fontWeight(.semibold)
                        .foregroundStyle(canSave ? accent : AppTheme.Colors.textMuted)
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: loadInitialState)
            .onChange(of: type) { _, _ in
                ensureCategoryMatchesType()
                ensureWalletMatchesType()
            }
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryView(type: type) { newId in
                    categoryId = newId
                }
            }
        }
    }

    // MARK: - Type Toggle

    private var typeToggle: some View {
        HStack(spacing: 0) {
            typeSegment(title: "Expense", value: "expense", color: AppTheme.Colors.expense)
            typeSegment(title: "Income", value: "income", color: AppTheme.Colors.income)
        }
        .padding(4)
        .background(AppTheme.Colors.surface)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(AppTheme.Colors.border, lineWidth: 1))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: type)
    }

    private func typeSegment(title: String, value: String, color: Color) -> some View {
        let isSelected = type == value
        return Button {
            HapticManager.light()
            type = value
        } label: {
            Text(title)
                .font(.appSans(15, weight: .semibold))
                .foregroundStyle(isSelected ? .white : AppTheme.Colors.textMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: isSelected ? [color, color.darker(by: 0.18)] : [.clear, .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Amount

    private var amountField: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            sectionLabel("Amount")
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.sm) {
                Text(DataStore.currencyInfo(for: store.currencyCode).symbol)
                    .font(.appSerif(30, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.textMuted)
                TextField("0", text: $amountText)
                    .font(.appSerif(44, weight: .semibold))
                    .foregroundStyle(accent)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, AppTheme.Spacing.xs)
        }
        .cardStyle()
    }

    // MARK: - Wallet

    private var walletSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            sectionLabel("Wallet")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(Array(visibleWallets.enumerated()), id: \.element.id) { index, wallet in
                        walletChip(wallet, index: index)
                    }
                }
                .padding(.horizontal, 1) // keeps stroke from clipping
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: walletId)
            }
        }
    }

    private func walletChip(_ wallet: Wallet, index: Int) -> some View {
        let isSelected = wallet.id == walletId
        return Button {
            HapticManager.light()
            walletId = wallet.id
        } label: {
            HStack(spacing: 8) {
                IconBadge(
                    symbol: IconMap.symbol(forWallet: wallet.id),
                    style: IconMap.pastel(forIndex: index),
                    size: 24
                )
                Text(wallet.name)
                    .font(.appSans(14, weight: .medium))
            }
            .padding(.leading, 6)
            .padding(.trailing, AppTheme.Spacing.md)
            .padding(.vertical, 6)
            .background(isSelected ? accent : AppTheme.Colors.surface)
            .foregroundStyle(isSelected ? .white : AppTheme.Colors.textPrimary)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(isSelected ? accent : AppTheme.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Category

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            sectionLabel("Category")
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: AppTheme.Spacing.sm), count: 4),
                spacing: AppTheme.Spacing.sm
            ) {
                ForEach(visibleCategories) { category in
                    categoryCell(category)
                }
                newCategoryCell
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: categoryId)
        }
    }

    private func categoryCell(_ category: AppCategory) -> some View {
        let isSelected = category.id == categoryId
        return Button {
            HapticManager.light()
            categoryId = category.id
        } label: {
            VStack(spacing: 6) {
                IconBadge(
                    symbol: IconMap.symbol(forCategory: category.id, storedIcon: category.emoji),
                    style: IconMap.pastel(forCategory: category.id),
                    size: 40
                )
                Text(category.label)
                    .font(.appSans(11))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .lineLimit(1)
                    .padding(.horizontal, AppTheme.Spacing.xs)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AppTheme.Spacing.xs)
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

    private var newCategoryCell: some View {
        Button {
            showingAddCategory = true
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.textMuted)
                Text("New")
                    .font(.appSans(11))
                    .foregroundStyle(AppTheme.Colors.textMuted)
                    .padding(.horizontal, AppTheme.Spacing.xs)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AppTheme.Spacing.xs)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(AppTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                    .foregroundStyle(AppTheme.Colors.border)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Details (date, note, tags)

    private var detailsSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            DatePicker("Date", selection: $date, displayedComponents: .date)
                .datePickerStyle(.compact)
                .font(.appSans(15))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .tint(accent)

            Divider()

            HStack {
                Text("Note")
                    .font(.appSans(15))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Spacer()
                TextField("Optional", text: $note)
                    .multilineTextAlignment(.trailing)
                    .font(.appSans(15))
            }

            Divider()

            HStack {
                Text("Tags")
                    .font(.appSans(15))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Spacer()
                TextField("comma, separated", text: $tagsText)
                    .multilineTextAlignment(.trailing)
                    .font(.appSans(15))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
        }
        .cardStyle()
    }

    // MARK: - Building Blocks

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.appSans(12, weight: .semibold))
            .foregroundStyle(AppTheme.Colors.textMuted)
    }

    // MARK: - State

    private func loadInitialState() {
        if let tx = editing {
            type = tx.type
            amountText = tx.amount == 0 ? "" : String(format: "%g", tx.amount)
            walletId = tx.walletId
            categoryId = tx.categoryId
            date = tx.date
            note = tx.note
            tagsText = tx.tags.joined(separator: ", ")
        } else {
            // Default to the user's default wallet (or the first available).
            walletId = wallets.first(where: { $0.isDefault })?.id
                ?? wallets.first?.id ?? ""
            date = initialDate ?? .now
            ensureCategoryMatchesType()
        }
    }

    /// Keeps the selected category valid for the current type.
    private func ensureCategoryMatchesType() {
        if !visibleCategories.contains(where: { $0.id == categoryId }) {
            categoryId = visibleCategories.first?.id ?? ""
        }
    }

    /// Clears the wallet selection if switching to "Income" leaves a credit
    /// card wallet selected — credit cards can't take normal income entries.
    private func ensureWalletMatchesType() {
        if !visibleWallets.contains(where: { $0.id == walletId }) {
            walletId = wallets.first(where: { $0.isDefault && !$0.isCreditCard })?.id
                ?? wallets.first(where: { !$0.isCreditCard })?.id ?? ""
        }
    }

    private func parsedTags() -> [String] {
        tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// Month-to-date spend for a category, excluding the transaction currently
    /// being edited so its old amount/category doesn't double-count.
    private func monthSpent(for categoryId: String) -> Double {
        allTransactions
            .filter {
                $0.categoryId == categoryId && $0.type == "expense" && $0.id != editing?.id
                    && Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .month)
            }
            .reduce(0) { $0 + $1.amount }
    }

    /// Fires a warning haptic the moment this save pushes a budgeted category
    /// from under 80% of its monthly limit to 80% or over.
    private func checkBudgetThreshold(beforeSpent: Double) {
        guard type == "expense",
              Calendar.current.isDate(date, equalTo: .now, toGranularity: .month),
              let limit = store.budgetLimits[categoryId], limit > 0
        else { return }
        let afterSpent = beforeSpent + amountValue
        if beforeSpent / limit < 0.8, afterSpent / limit >= 0.8 {
            HapticManager.warning()
        }
    }

    private func save() {
        guard canSave else { return }

        let beforeSpent = monthSpent(for: categoryId)

        // Auto-tag to the active trip for expenses; preserve an existing trip tag on edit.
        let tripId: String? = {
            guard type == "expense" else { return nil }
            if let tx = editing { return tx.tripId ?? store.activeTripId }
            return store.activeTripId
        }()

        if let tx = editing {
            tx.type = type
            tx.amount = amountValue
            tx.walletId = walletId
            tx.categoryId = categoryId
            tx.date = date
            tx.note = note
            tx.tags = parsedTags()
            tx.tripId = tripId
        } else {
            let tx = Transaction(
                type: type,
                amount: amountValue,
                currencyCode: store.currencyCode,
                categoryId: categoryId,
                walletId: walletId,
                note: note,
                tags: parsedTags(),
                tripId: tripId,
                date: date
            )
            modelContext.insert(tx)
        }

        try? modelContext.save()
        checkBudgetThreshold(beforeSpent: beforeSpent)
        HapticManager.impact()
        dismiss()
    }
}

// MARK: - Color Helper

private extension Color {
    /// Returns a deeper variant of this color by reducing its HSB brightness —
    /// used for the active type-toggle segment's gradient.
    func darker(by amount: CGFloat) -> Color {
        let uiColor = UIColor(self)
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return Color(hue: hue, saturation: saturation, brightness: max(0, brightness - amount), opacity: alpha)
    }
}

#Preview {
    AddTransactionView()
        .environment(DataStore())
        .modelContainer(DataStore.modelContainer)
}
