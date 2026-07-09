//
//  AddCategoryView.swift
//  Budget Control
//
//  Sheet for creating a custom expense or income category. Opened from the
//  "+ New" cell in AddTransactionView. The chosen SF Symbol is stored in the
//  model's emoji field (ASCII-only, same pattern as Plans forms).
//

import SwiftUI
import SwiftData

struct AddCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    /// "expense" or "income" — locked to the transaction type that opened this sheet.
    var type: String
    /// Called with the new category's id after a successful save.
    var onCreated: (String) -> Void

    @State private var label = ""
    @State private var symbol = "tag.fill"

    private let expenseSymbols = [
        "tag.fill", "fork.knife", "bus", "house.fill", "film", "cross.case.fill",
        "bag.fill", "airplane", "pawprint.fill", "book.fill", "car.fill", "leaf.fill",
    ]
    private let incomeSymbols = [
        "sparkles", "briefcase.fill", "laptopcomputer", "gift.fill",
        "chart.line.uptrend.xyaxis", "dollarsign.circle.fill", "building.2.fill",
        "star.fill", "heart.fill", "creditcard.fill", "banknote.fill", "globe",
    ]

    private var symbolChoices: [String] {
        type == "income" ? incomeSymbols : expenseSymbols
    }

    private var canSave: Bool {
        !label.trimmingCharacters(in: .whitespaces).isEmpty
    }

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
                                TextField("Category name", text: $label)
                                    .multilineTextAlignment(.trailing)
                                    .font(.appSans(15))
                            }
                            Divider()
                            HStack {
                                Text("Type")
                                    .font(.appSans(15))
                                    .foregroundStyle(AppTheme.Colors.textPrimary)
                                Spacer()
                                Text(type == "income" ? "Income" : "Expense")
                                    .font(.appSans(15, weight: .medium))
                                    .foregroundStyle(type == "income" ? AppTheme.Colors.income : AppTheme.Colors.expense)
                            }
                        }
                        .cardStyle()

                        iconPicker
                    }
                    .padding(AppTheme.Spacing.md)
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create", action: save)
                        .fontWeight(.semibold)
                        .foregroundStyle(canSave ? AppTheme.Colors.accent : AppTheme.Colors.textMuted)
                        .disabled(!canSave)
                }
            }
            .onAppear {
                symbol = symbolChoices.first ?? "tag.fill"
            }
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
                        IconBadge(symbol: choice, style: .lavender, size: 36)
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

    private func save() {
        guard canSave else { return }
        let trimmed = label.trimmingCharacters(in: .whitespaces)
        let id = "cat-\(UUID().uuidString.prefix(8))"
        let category = AppCategory(
            id: id,
            label: trimmed,
            emoji: symbol,
            colorHex: "#8A7A66",
            type: type,
            isDefault: false
        )
        modelContext.insert(category)
        try? modelContext.save()
        onCreated(id)
        dismiss()
    }
}

#Preview {
    AddCategoryView(type: "expense") { _ in }
        .modelContainer(DataStore.modelContainer)
}
