# Gyoza Budget

Gyoza Budget is a SwiftUI budgeting app for iOS. It tracks income and expenses by category, measures spending against monthly targets, and manages savings goals with a progress bar and completion state.

<p align="center">
  <img src="https://github.com/user-attachments/assets/80440c4e-981c-4193-9100-b46506158c95" width="300"/>
  <img src="https://github.com/user-attachments/assets/caeb55a8-fd47-4d11-a6a9-66d5373d1281" width="300"/>
  <img src="https://github.com/user-attachments/assets/dca02b6a-6b59-42b5-89fb-6f70e6abb3a9" width="300"/>
</p>

## Current release: v3.6

Marketing version **3.6**, build **9**.

## What it does

Transactions get recorded with an amount, type (income or expense), category, date, an optional note, and an optional receipt photo. The dashboard shows a balance summary and totals by category. Monthly budgets let you set a spending target per category and see how much is used. Savings goals work the same way - add money against a target until it is reached, at which point the goal marks itself complete.

Quick Add is a fast entry sheet for expenses. It opens from the dashboard or from a Shortcut, using App Intents. New users go through a two-step onboarding that sets currency first, then walks through adding a transaction, creating a budget, and setting a savings goal - in that order.

The full Transactions screen is searchable and grouped by month. Swipe left on a row to delete; the action is a red plate with a clear X and Delete label so it stays readable in every theme (including Dark, where the app accent is near-white). On the dashboard recent list, long-press a row for Delete in the context menu so vertical scroll is not fighting a custom swipe gesture.

The app has three themes: Light, Dark, and Zen. Theme and currency are stored in `AppStorage` and apply across the whole app.

## What changed in v3.6

Compared to **v3.5** (scroll fix only for recent-row swipe). This release is a broader polish and reliability pass.

### Transactions and delete UX
- Swipe-to-delete on the full Transactions list uses a fixed destructive red, a bold **X** icon, and a **Delete** label. It no longer inherits the near-white Dark accent tint (which looked like a blank white chip)
- Transactions list is a native `List`: search notes and categories, group by month, empty and no-results states via `ContentUnavailableView`
- Dashboard recent rows drop the custom drag-to-delete overlay. Tap opens the row; long-press context menu Delete uses `xmark.circle.fill` so scroll stays clean

### Money input and currency
- Shared locale-aware `AppPreferences.parseAmount` for typed amounts (`1,000`, decimals, whitespace). Used for new/edit transaction, Quick Add, budget targets, and savings goal amounts
- Shared `currencySymbol(for:)` so field symbols always match the selected currency format
- Default currency is clamped to the supported list (USD, EUR, GBP, JPY, AUD, CAD, MMK)
- Unit tests cover parse amount edge cases (empty, garbage, negatives, grouped thousands)

### Settings
- Settings rebuilt as a standard `Form` (Appearance, Preferences, Data)
- Reset All Data shows an error alert if the context save fails

### Savings goals
- Goal detail extracted into its own `GoalDetailView` (add money, adjust amount, delete)
- Completion uses cent-rounded comparison so floating-point edges do not leave a goal half-done
- Save failures surface a clear alert instead of failing silently
- List swipe-delete removed; delete lives in the detail confirmation flow

### Dashboard, budget, and summary
- Dashboard income/expense/category/month totals computed in one pass (`DashboardStats`)
- Budget preview and monthly budget use clearer over-budget (red) / near-limit (orange) status colours
- Budget rows expose accessibility labels and percent-used values
- `BudgetSection` is data-only; budget UI lives in `MonthlyBudgetView`
- Financial summary and empty states use shared panel cards and `ContentUnavailableView`
- Amounts use monospaced digits more consistently

### Theme and structure
- Removed `ThemeColors.swift` and unused premium gradient tokens; views use `ThemeManager` / `AppTheme`
- Premium cards simplified to a flat theme fill with light emphasis stroke
- `theme.destructive` for delete actions that must not follow the app accent
- Compact scroll-title chrome removed from the dashboard for a simpler layout

### Reliability
- If the persistent SwiftData container cannot be created, the app falls back to an in-memory store instead of crashing on launch
- Quick Add deep link opens via `OpenURLIntent` without the old OS version gate
- `SavingsGoal.createdDate` is non-optional with a default
- App marketing version **3.6**, project build **9**

## v3.5

- Recent Transactions list scrolls smoothly when a finger starts on a transaction row - the swipe-to-delete gesture no longer blocks vertical scroll

## v3.4

- Reset All Data now clears transactions, budgets, and savings goals together
- Swipe-to-delete is consistent across all transaction lists
- Transaction rows show a date instead of repeating the type label
- Savings goal Add Money validates the input before submitting
- Primary button contrast improved in Zen and dark mode
- Dead code removed, shared components consolidated

Minor fixes: Quick Add currency symbol rendering, Set Budget button layout.

## v3.3

- Current-month budget totals now exclude future-dated transactions
- Budget row identity stabilised so progress animations do not jump
- Transaction edit amount no longer shows floating-point artifacts
- Quick Add deep-link fixed so the sheet reopens reliably on repeated taps
- Quick Add currency symbol matches the selected currency format

## v3.2

- Spring-based transitions on the dashboard and onboarding screens
- Quick Add stays usable when the keyboard is open or content needs to scroll
- Transaction deletion asks for confirmation from the edit view
- Receipt image processing moved off the main thread

## v3.1

- App build targets restricted to iPhone and iPad, removing accidental macOS and visionOS support

## v3.0

Rebuilt from a SwiftData starter template into a working budgeting app. Added the full transaction model, monthly budgets, savings goals, onboarding, Quick Add with App Intents, three themes, currency settings, and the financial summary views.

## Tech

- SwiftUI
- SwiftData
- AppStorage
- App Intents
- PhotosPicker
- iOS

## Related

[Gyoza Island](https://github.com/alfredswift31-botty/GyozaIsland) is a macOS notch panel app built alongside this one.
