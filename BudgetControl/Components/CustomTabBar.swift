//
//  CustomTabBar.swift
//  Budget Control
//
//  Custom bottom tab bar replacing the system TabView. A white surface bar with
//  a hairline top border and five items. Each item shows an SF Symbol, a small
//  accent dot that appears only on the active tab, and a caption label. Active
//  items use the accent color; inactive use textMuted. The bar's surface extends
//  into the bottom safe area while content stays above the home indicator.
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int

    @Namespace private var activeDotNamespace

    private struct TabItem {
        let icon: String
        let label: String
    }

    private let tabs: [TabItem] = [
        TabItem(icon: "house.fill", label: "Home"),
        TabItem(icon: "chart.pie.fill", label: "Stats"),
        TabItem(icon: "calendar", label: "Calendar"),
        TabItem(icon: "checklist", label: "Plans"),
        TabItem(icon: "list.bullet", label: "All"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                tabButton(index: index, tab: tab)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        // Content is exactly 56pt; the surface bleeds into the bottom safe area
        // (home indicator) without adding any extra height to the bar.
        .background(
            AppTheme.Colors.surface
                .ignoresSafeArea(edges: .bottom)
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppTheme.Colors.border)
                .frame(height: 1)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
    }

    private func tabButton(index: Int, tab: TabItem) -> some View {
        let isActive = selectedTab == index
        let color = isActive ? AppTheme.Colors.accent : AppTheme.Colors.textMuted

        return Button {
            HapticManager.light()
            selectedTab = index
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(color)

                ZStack {
                    if isActive {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(AppTheme.Colors.accent)
                            .matchedGeometryEffect(id: "activeDot", in: activeDotNamespace)
                    }
                }
                .frame(width: 4, height: 4)

                Text(tab.label)
                    .font(.appSans(9, weight: .medium))
                    .foregroundStyle(color)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selected = 0
        var body: some View {
            VStack {
                Spacer()
                CustomTabBar(selectedTab: $selected)
            }
            .background(AppTheme.Colors.background)
        }
    }
    return PreviewWrapper()
}
