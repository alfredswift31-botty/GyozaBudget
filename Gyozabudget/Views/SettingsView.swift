import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager
    @Query(sort: [SortDescriptor(\Transaction.date, order: .reverse)]) private var transactions: [Transaction]
    @Query private var budgetTargets: [BudgetTarget]
    @Query private var savingsGoals: [SavingsGoal]

    @AppStorage(AppPreferences.themePreferenceKey) private var themePreferenceRaw = ThemeOption.light.rawValue
    @AppStorage(AppPreferences.currencyCodeKey) private var currencyCode = AppPreferences.defaultCurrencyCode
    @AppStorage(AppPreferences.rememberLastQuickAddCategoryKey) private var rememberLastQuickAddCategory = false
    @AppStorage(AppPreferences.quickAddHapticsEnabledKey) private var quickAddHapticsEnabled = true

    @State private var showingResetConfirmation = false
    @State private var resetErrorMessage: String?

    private var theme: AppTheme {
        themeManager.currentTheme
    }

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $themePreferenceRaw) {
                    ForEach(ThemeOption.allCases) { option in
                        Text(option.title).tag(option.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }
            .listRowBackground(theme.cardBackground)

            Section {
                Picker("Currency", selection: $currencyCode) {
                    ForEach(AppPreferences.supportedCurrencyCodes, id: \.self) { code in
                        Text(code).tag(code)
                    }
                }
                Toggle("Remember last Quick Add category", isOn: $rememberLastQuickAddCategory)
                Toggle("Haptic feedback for Quick Add", isOn: $quickAddHapticsEnabled)
            } header: {
                Text("Preferences")
            } footer: {
                Text("The selected currency is used for all amounts across the app.")
            }
            .listRowBackground(theme.cardBackground)

            Section {
                Button("Reset All Data", role: .destructive) {
                    showingResetConfirmation = true
                }
            } header: {
                Text("Data")
            } footer: {
                Text("Delete all transactions, budgets, and savings goals.")
            }
            .listRowBackground(theme.cardBackground)
        }
        .scrollContentBackground(.hidden)
        .background(theme.background.ignoresSafeArea())
        .tint(theme.accent)
        .navigationTitle("Settings")
        .confirmationDialog("Reset all data?", isPresented: $showingResetConfirmation, titleVisibility: .visible) {
            Button("Delete All Data", role: .destructive) {
                resetAllData()
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert(
            "Couldn't Reset Data",
            isPresented: Binding(
                get: { resetErrorMessage != nil },
                set: { if !$0 { resetErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(resetErrorMessage ?? "")
        }
    }

    private func resetAllData() {
        withAnimation {
            for transaction in transactions { modelContext.delete(transaction) }
            for target in budgetTargets { modelContext.delete(target) }
            for goal in savingsGoals { modelContext.delete(goal) }
            do {
                try modelContext.save()
            } catch {
                resetErrorMessage = error.localizedDescription
            }
        }
    }
}
