//
//  ContentView.swift
//  Budget Control
//
//  Root gate: shows onboarding on first launch, otherwise the main tab shell.
//  Runs first-launch seeding and recurring-rule processing on appear.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    // Seed synchronously so returning users never flash the onboarding pager.
    @State private var hasOnboarded = UserDefaults.standard.bool(forKey: "hasOnboarded")

    var body: some View {
        Group {
            if hasOnboarded {
                MainTabView()
            } else {
                OnboardingView(onFinish: completeOnboarding)
            }
        }
        .preferredColorScheme(store.isDarkMode ? .dark : .light)
        .tint(AppTheme.Colors.accent)
        .task {
            store.seedIfNeeded(context: modelContext)
            store.refreshCalendarPeriodIfNeeded()
            store.processRecurringRules(context: modelContext)
            hasOnboarded = store.hasOnboarded
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                store.refreshCalendarPeriodIfNeeded()
                store.processRecurringRules(context: modelContext)
            }
        }
    }

    private func completeOnboarding() {
        store.hasOnboarded = true
        hasOnboarded = true
    }
}

#Preview {
    ContentView()
        .environment(DataStore())
        .modelContainer(DataStore.modelContainer)
}
