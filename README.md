# Gyoza Budget

Gyoza Budget is a SwiftUI personal finance app designed to make daily expense tracking, monthly budgeting, and savings goals feel simple, fast, and visually polished.

## Version 3.0 Highlights

Gyoza Budget v3.0 transforms the original SwiftData starter project into a full budgeting app with real product structure, onboarding, themes, and guided user flow.

## Version 3.1 Update

- App compatibility is now explicitly limited to iPhone and iPad builds, removing accidental macOS and visionOS target support.

## Version 3.4 Update

- Reset All Data now clears transactions, budgets, and savings goals.
- Swipe-to-delete is now reused consistently across transaction lists.
- Transaction rows now show a date fallback instead of redundant type text.
- Savings goal Add Money validation is safer.
- Zen/theme primary button contrast improved.
- Removed dead code and cleaned shared components.

Minor fixes:
- Fixed Quick Add currency symbol rendering issue
- Fixed Set Budget button layout inconsistency

## Version 3.3 Update

- Fixed current-month budget totals so future-dated transactions are excluded.
- Stabilized budget row identity for smoother progress animations.
- Improved transaction edit amount formatting to avoid floating-point display artifacts.
- Fixed repeated Quick Add deep-link triggering so the sheet reopens reliably.
- Aligned the Quick Add currency symbol with the selected currency formatting.

## Version 3.2 Update

- Improved dashboard and onboarding motion with smoother spring-based transitions.
- Refined Quick Add so expense entry remains comfortable when the keyboard is open or content needs to scroll.
- Added clearer transaction deletion confirmation from the edit flow.
- Improved transaction deletion behavior across dashboard, transaction, and financial summary views.
- Moved receipt image processing off the main UI path for a more responsive attachment flow.

## Version 3.0 Update

Version 3.0 is focused on turning Gyoza Budget into a more complete, polished, and practical budgeting companion. This update brings the app closer to a real daily finance tool with clearer setup, faster expense entry, better visual organization, and more ways to personalize the experience.

### Update Summary

- Expanded the app from basic data storage into a full personal finance workflow.
- Added structured transaction tracking for income, expenses, categories, dates, notes, and receipt images.
- Introduced monthly category budgets so users can compare spending against planned targets.
- Added savings goals with progress tracking and completion state.
- Added onboarding and guided setup so first-time users know what to do next.
- Added Quick Add support for faster expense entry.
- Added App Intent support for opening Quick Add through shortcuts or deep links.
- Added Light, Dark, and Zen themes with shared app preferences.
- Improved dashboard hierarchy, summary cards, spacing, and theme-aware styling.
- Added settings for currency, theme, Quick Add preferences, onboarding reset, and data reset.
- Updated the project release version to `3.0` with build number `3`.

### What’s New in v3.0

- Built a full transaction tracking system with income, expense, categories, notes, dates, and receipt image support.
- Added monthly budget targets by category.
- Added savings goals with progress tracking and completion logic.
- Introduced a two-step onboarding flow with currency setup.
- Added a guided setup journey from first transaction → budget setup → savings goal.
- Added Light, Dark, and Zen theme modes.
- Added shared app preferences for theme, currency, onboarding, and quick-add behavior.
- Added Quick Add expense flow for faster transaction entry.
- Added App Intent support for opening Quick Add through shortcuts/deep links.
- Added financial summary views for balance, income, and expenses.
- Added settings for theme, currency, quick-add preferences, and data reset.
- Improved dashboard hierarchy, card design, spacing, and theme-aware UI polish.
- Optimised Dark and Zen mode card rendering for smoother scrolling.

## Core Features

### Expense & Income Tracking
Track transactions with amount, type, category, date, note, and optional receipt image.

### Monthly Budgeting
Set monthly category targets and monitor spending progress.

### Savings Goals
Create savings goals, track progress, and manage goal completion.

### Quick Add
Add expenses quickly through a streamlined entry flow.

### Guided Setup
New users are guided through the first important actions:
1. Add first transaction
2. Set first budget
3. Create first savings goal

### Theme System
Includes three visual modes:
- Light Mode
- Dark Mode
- Zen Mode

### Financial Summary
View income, expenses, and balance summaries with transaction breakdowns.

## Tech Stack

- SwiftUI
- SwiftData
- AppStorage
- App Intents
- PhotosPicker
- Custom theme system
- iOS app architecture

## Project Status

Version 3.0 is a major feature and UI upgrade focused on turning the app from a template into a usable personal budgeting product.

## Version

Current release: `v3.4`
