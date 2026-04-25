import SwiftUI

struct OnboardingView: View {
    private enum Step: Int {
        case welcome
        case setup
    }

    @EnvironmentObject private var themeManager: ThemeManager
    @AppStorage(AppPreferences.currencyCodeKey) private var currencyCode = AppPreferences.defaultCurrencyCode

    @State private var step: Step = .welcome

    let onComplete: () -> Void

    private var theme: AppTheme {
        themeManager.currentTheme
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 28) {
                progressLabel

                Spacer(minLength: 0)

                Group {
                    switch step {
                    case .welcome:
                        welcomeStep
                    case .setup:
                        setupStep
                    }
                }

                Spacer(minLength: 0)

                primaryButton
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
        .animation(.easeInOut(duration: 0.22), value: step)
    }

    private var progressLabel: some View {
        Text(step == .welcome ? "1 of 2" : "2 of 2")
            .font(.caption.weight(.semibold))
            .foregroundColor(theme.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(theme.cardBackground)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(theme.border, lineWidth: 1)
            )
    }

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Image("gyoza_icon")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            VStack(alignment: .leading, spacing: 12) {
                Text("Welcome to Gyoza Budget")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)

                Text("Track spending, set budgets, and stay in control without getting buried in setup.")
                    .font(.title3)
                    .foregroundColor(theme.textSecondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                onboardingPoint(title: "Track what matters", detail: "Capture expenses and income quickly from the main dashboard.")
                onboardingPoint(title: "Set simple limits", detail: "Use monthly targets when you're ready to keep spending in check.")
                onboardingPoint(title: "Build savings habits", detail: "Add goals later without slowing down your first session.")
            }
        }
    }

    private var setupStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Confirm your setup")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)

                Text("Pick the currency you want to see across balances, budgets, and savings.")
                    .font(.title3)
                    .foregroundColor(theme.textSecondary)
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("Currency")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(theme.textPrimary)

                Menu {
                    ForEach(AppPreferences.supportedCurrencyCodes, id: \.self) { code in
                        Button(code) {
                            currencyCode = code
                        }
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(currencyCode)
                                .font(.title3.weight(.semibold))
                                .foregroundColor(theme.textPrimary)
                            Text("Used everywhere in the app")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(theme.textSecondary)
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(theme.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(theme.border, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                Text("You can change this later in Settings, then start with your first transaction now.")
                    .font(.footnote)
                    .foregroundColor(theme.textSecondary)
            }
        }
    }

    private var primaryButton: some View {
        Button(action: handlePrimaryAction) {
            Text(step == .welcome ? "Continue" : "Add your first transaction")
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(theme.accent)
                .foregroundColor(theme.background)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func onboardingPoint(title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(theme.accent)
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(theme.textPrimary)
                Text(detail)
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
            }
        }
    }

    private var backgroundColors: [Color] {
        if theme.colorScheme == .dark {
            return [
                theme.background,
                theme.surface,
                theme.cardBackground
            ]
        }

        return [
            theme.background,
            theme.cardBackground,
            theme.surface
        ]
    }

    private func handlePrimaryAction() {
        switch step {
        case .welcome:
            step = .setup
        case .setup:
            onComplete()
        }
    }
}
