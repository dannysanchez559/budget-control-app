//
//  EmptyStateView.swift
//  Budget Control
//
//  Shared empty-state treatment: a centered pastel IconBadge with the section's
//  message below it. Used wherever a list or section has no records yet, so
//  every empty state in the app reads consistently instead of plain gray text.
//

import SwiftUI

struct EmptyStateView: View {
    /// SF Symbol shown in the badge — reuse the section's existing icon where one exists.
    var symbol: String
    /// Pastel theme — reuse the section's existing pastel where one exists.
    var pastel: PastelStyle
    var title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            IconBadge(symbol: symbol, style: pastel, size: 56)

            Text(title)
                .font(.appSans(AppTheme.Typography.fontLabel))
                .foregroundStyle(AppTheme.Colors.textMuted)
                .multilineTextAlignment(.center)

            if let subtitle {
                Text(subtitle)
                    .font(.appSans(AppTheme.Typography.fontLabel))
                    .foregroundStyle(AppTheme.Colors.textMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

#Preview {
    VStack(spacing: 24) {
        EmptyStateView(symbol: "arrow.triangle.2.circlepath", pastel: .peach, title: "No recurring rules yet")
        EmptyStateView(
            symbol: "magnifyingglass",
            pastel: .sky,
            title: "Search your transactions",
            subtitle: "Find by note, category, wallet, amount, or tag"
        )
    }
    .padding()
    .background(AppTheme.Colors.background)
}
