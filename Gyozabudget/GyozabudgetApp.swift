//
//  GyozabudgetApp.swift
//  Gyozabudget
//
//  Created by Aung Hpone Moe on 10/04/2026.
//

import SwiftUI
import SwiftData

@main
struct GyozabudgetApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var openQuickAdd = false
    @AppStorage(AppPreferences.hasCompletedOnboardingKey) private var hasCompletedOnboarding = false
    @AppStorage(AppPreferences.themePreferenceKey) private var themePreferenceRaw = ThemeOption.light.rawValue

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Transaction.self,
            BudgetTarget.self,
            SavingsGoal.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    private var preferredTheme: ColorScheme? {
        ThemeOption(rawValue: themePreferenceRaw)?.colorScheme
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView(showingQuickAddExpense: $openQuickAdd)
                } else {
                    OnboardingView {
                        completeOnboarding()
                    }
                }
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
            .onAppear {
                themeManager.applyPreference(themePreferenceRaw)
            }
            .onChange(of: themePreferenceRaw) { _, newValue in
                themeManager.applyPreference(newValue)
            }
            .environmentObject(themeManager)
            .tint(themeManager.currentTheme.accent)
            .preferredColorScheme(preferredTheme)
        }
        .modelContainer(sharedModelContainer)
    }

    private func handleDeepLink(_ url: URL) {
        if url.scheme == "gyozabudget" && (url.host == "quick-add" || url.path.contains("quick-add")) {
            // Reset first so a repeat deep-link with the same value still
            // produces a state transition that SwiftUI can observe.
            openQuickAdd = false
            DispatchQueue.main.async {
                openQuickAdd = true
            }
        }
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true

        DispatchQueue.main.async {
            openQuickAdd = true
        }
    }
}
