# Gyoza Budget

Gyoza Budget is a SwiftUI budgeting app for iOS. It tracks income and expenses by category, measures spending against monthly targets, and manages savings goals with a progress bar and completion state.

<p align="center">
  <img src="https://github.com/user-attachments/assets/80440c4e-981c-4193-9100-b46506158c95" width="300"/>
  <img src="https://github.com/user-attachments/assets/caeb55a8-fd47-4d11-a6a9-66d5373d1281" width="300"/>
  <img src="https://github.com/user-attachments/assets/dca02b6a-6b59-42b5-89fb-6f70e6abb3a9" width="300"/>
</p>

## Current release: v3.6

## What it does

Transactions get recorded with an amount, type (income or expense), category, date, an optional note, and an optional receipt photo. The dashboard shows a balance summary and totals by category. Monthly budgets let you set a spending target per category and see how much is used. Savings goals work the same way - add money against a target until it is reached, at which point the goal marks itself complete.

Quick Add is a fast entry sheet for expenses. It opens from the dashboard or from a Shortcut, using App Intents. New users go through a two-step onboarding that sets currency first, then walks through adding a transaction, creating a budget, and setting a savings goal - in that order.

The full Transactions screen is searchable and grouped by month. Swipe left on a row to delete; the action is a red plate with a clear X and Delete label so it stays readable in every theme (including Dark, where the app accent is near-white).

The app has three themes: Light, Dark, and Zen. Theme and currency are stored in `AppStorage` and apply across the whole app.

## What changed in v3.6

- Swipe-to-delete no longer looks like a blank white chip in Dark mode. The action uses a fixed destructive red, a bold X icon, and a Delete label, instead of inheriting the near-white app accent tint
- Transactions list is searchable (notes and categories) and grouped by month
- Locale-aware amount parsing for typed money (`1,000` and similar) with unit tests; currency symbol helper shared with Quick Add
- Settings rebuilt as a standard Form (theme, currency, Quick Add preferences, Reset All Data)
- Theme cleanup: dead theme tokens and `ThemeColors.swift` removed; cards and controls use the shared `AppTheme` path only
- Dashboard totals computed in one pass; budget progress uses clearer over/near-limit colours and accessibility labels
- SwiftData store falls back to in-memory if persistent container creation fails, so the app still launches

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
