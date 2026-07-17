//
//  BudgetCard.swift
//  Budget Control
//
//  A pastel tile for the Home budgets strip: category icon + label on one row,
//  month-to-date spend, optional limit + progress bar. Pass `limit: nil` for
//  categories without a budget set. Fixed width for horizontal scrolling.
//

import SwiftUI

struct BudgetCard: View {
    @Environment(DataStore.self) private var store

    var category: AppCategory
    var spent: Double
    /// Monthly limit. `nil` means no limit has been set for this category.
    var limit: Double?
    var index: Int

    // Drives the progress bar filling from zero when the card first appears.
    @State private var appeared = false

    private let cardPadding: CGFloat = 16

    private var pastel: PastelStyle { IconMap.pastel(forIndex: index) }

    private var hasLimit: Bool { (limit ?? 0) > 0 }

    private var ratio: CGFloat {
        guard let limit, limit > 0 else { return 0 }
        return min(max(CGFloat(spent / limit), 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: AppTheme.Spacing.sm) {
                IconBadge(
                    symbol: IconMap.symbol(forCategory: category.id, storedIcon: category.emoji),
                    style: pastel,
                    size: 32
                )
                Text(category.label)
                    .font(.appSans(AppTheme.Typography.fontLabel, weight: .semibold))
                    .foregroundStyle(pastel.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(store.formatAmount(spent))
                    .font(.appSans(AppTheme.Typography.fontCardNumber, weight: .semibold))
                    .foregroundStyle(pastel.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if hasLimit, let limit {
                    Text("of \(store.formatAmount(limit))")
                        .font(.appSans(AppTheme.Typography.fontCaption, weight: .regular))
                        .foregroundStyle(pastel.text.opacity(0.7))
                        .lineLimit(1)
                } else {
                    Text("No limit set")
                        .font(.appSans(AppTheme.Typography.fontCaption, weight: .medium))
                        .foregroundStyle(pastel.text.opacity(0.55))
                        .lineLimit(1)
                }
            }
            .padding(.top, AppTheme.Spacing.sm)

            if hasLimit {
                progressBar
                    .padding(.top, 10)
                    .padding(.bottom, 10)
            }
        }
        .padding(.top, cardPadding)
        .padding(.horizontal, cardPadding)
        .padding(.bottom, cardPadding + 4)
        .frame(width: 150, height: 110, alignment: .topLeading)
        .background(pastel.fill)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .opacity(hasLimit ? 1 : 0.82)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
                appeared = true
            }
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(pastel.text.opacity(0.15))
                Capsule()
                    .fill(pastel.text)
                    .frame(width: (appeared ? ratio : 0) * geo.size.width)
            }
        }
        .frame(height: 4)
    }
}

#Preview {
    let cat = AppCategory(id: "cat-food", label: "Food", emoji: "🍕", colorHex: "#E07060")
    return HStack(spacing: 12) {
        BudgetCard(category: cat, spent: 54, limit: 250, index: 0)
        BudgetCard(category: cat, spent: 0, limit: nil, index: 1)
    }
    .environment(DataStore())
    .padding()
    .background(AppTheme.Colors.background)
}
