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

    private var theme: AppTheme {
        themeManager.currentTheme
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header

                sectionCard(title: "Appearance") {
                    Picker("Theme", selection: $themePreferenceRaw) {
                        ForEach(ThemeOption.allCases) { option in
                            Text(option.title).tag(option.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(theme.accent)
                }

                sectionCard(title: "Preferences") {
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Currency")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(theme.textPrimary)
                                Text("Select the display currency for amounts.")
                                    .font(.caption)
                                    .foregroundColor(theme.textSecondary)
                            }
                            Spacer()
                            Menu {
                            ForEach(AppPreferences.supportedCurrencyCodes, id: \.self) { code in
                                Button(code) {
                                    currencyCode = code
                                }
                            }
                        } label: {
                                Text(currencyCode)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(theme.textPrimary)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(theme.cardBackground)
                                    )
                            }
                        }

                        settingToggle(
                            title: "Remember last Quick Add category",
                            isOn: $rememberLastQuickAddCategory
                        )

                        settingToggle(
                            title: "Haptic feedback for Quick Add",
                            isOn: $quickAddHapticsEnabled
                        )
                    }
                }

                sectionCard(title: "Data") {
                    VStack(spacing: 12) {
                        Button(action: {
                            showingResetConfirmation = true
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Reset All Data")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(theme.textPrimary)
                                    Text("Delete every transaction from the app.")
                                        .font(.caption)
                                        .foregroundColor(theme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "trash")
                                    .foregroundColor(theme.textPrimary)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(theme.cardBackground)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(theme.background.ignoresSafeArea())
        .confirmationDialog("Reset all data?", isPresented: $showingResetConfirmation, titleVisibility: .visible) {
            Button("Delete All Transactions", role: .destructive) {
                resetAllData()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Settings")
                .font(.largeTitle.weight(.bold))
                .foregroundColor(theme.textPrimary)
            Text("Control app preferences, appearance, and data management.")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundColor(theme.textPrimary)
            content()
        }
        .padding(20)
        .appPanelCard(cornerRadius: 26, emphasized: true)
    }

    private func settingToggle(title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(theme.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(theme.border.opacity(0.7), lineWidth: 1)
        )
        .toggleStyle(AppSwitchToggleStyle())
    }

    private func resetAllData() {
        withAnimation {
            for transaction in transactions { modelContext.delete(transaction) }
            for target in budgetTargets { modelContext.delete(target) }
            for goal in savingsGoals { modelContext.delete(goal) }
            do {
                try modelContext.save()
            } catch {
                print("Failed to reset data: \(error)")
            }
        }
    }
}
