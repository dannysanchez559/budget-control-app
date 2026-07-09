//
//  MainTabView.swift
//  Budget Control
//
//  App shell. A custom bottom tab bar (CustomTabBar) drives a ZStack of the
//  five destination screens, with the floating add button overlaid above the
//  bar. The system TabView is no longer used. Each destination owns its own
//  NavigationStack and hides the system tab bar.
//

import SwiftUI

struct MainTabView: View {

    // 0: Home, 1: Stats, 2: Calendar, 3: Plans, 4: All
    @State private var selectedTab: Int = 0
    /// Fresh context each time + is tapped — guarantees the sheet picks up the
    /// current calendar selection (item-based sheet, not isPresented).
    @State private var addTransactionContext: AddTransactionContext?

    /// Calendar tab exposes the selected day for new transactions.
    @State private var calendarSelectedDate: Date = Calendar.current.startOfDay(for: .now)

    var body: some View {
        ZStack(alignment: .bottom) {
            // Keep every tab mounted so scroll position and month selection persist.
            tabLayer(0) { HomeView() }
            tabLayer(1) { StatsView() }
            tabLayer(2) { CalendarView(selectedDate: $calendarSelectedDate) }
            tabLayer(3) { PlansView() }
            tabLayer(4) { AllTransactionsView() }

            // Floating add button — hidden on the Plans tab (index 3).
            if selectedTab != 3 {
                HStack {
                    Spacer()
                    FloatingAddButton {
                        let initialDate = selectedTab == 2
                            ? Calendar.current.startOfDay(for: calendarSelectedDate)
                            : nil
                        addTransactionContext = AddTransactionContext(initialDate: initialDate)
                    }
                    .padding(.trailing, 20)
                }
                .padding(.bottom, AppTheme.Layout.floatingActionBottomOffset)
            }

            // Custom tab bar pinned to the bottom; Spacer pushes content up.
            VStack(spacing: 0) {
                Spacer()
                CustomTabBar(selectedTab: $selectedTab)
            }
        }
        .sheet(item: $addTransactionContext) { context in
            AddTransactionView(editing: nil, initialDate: context.initialDate)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private func tabLayer<T: View>(_ index: Int, @ViewBuilder content: () -> T) -> some View {
        content()
            .toolbar(.hidden, for: .tabBar)
            .opacity(selectedTab == index ? 1 : 0)
            .allowsHitTesting(selectedTab == index)
            .accessibilityHidden(selectedTab != index)
    }
}

/// Payload for presenting a new-transaction sheet with an optional pre-filled date.
private struct AddTransactionContext: Identifiable {
    let id = UUID()
    let initialDate: Date?
}

#Preview {
    MainTabView()
        .environment(DataStore())
        .modelContainer(DataStore.modelContainer)
}
