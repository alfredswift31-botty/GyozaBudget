//
//  ContentView.swift
//  Gyozabudget
//
//  Created by Aung Hpone Moe on 10/04/2026.
//

import SwiftUI
import SwiftData
import PhotosUI
#if canImport(UIKit)
import UIKit
#endif

struct ContentView: View {
    private enum GuidedStep: Int {
        case firstTransaction
        case budgetSetup
        case savingsGoal
        case allSet
    }

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager
    @Query(sort: [SortDescriptor(\Transaction.date, order: .reverse)]) private var transactions: [Transaction]
    @Query(sort: [SortDescriptor(\BudgetTarget.month, order: .reverse)]) private var budgetTargets: [BudgetTarget]
    @Query(sort: [SortDescriptor(\SavingsGoal.createdDate, order: .reverse)]) private var savingsGoals: [SavingsGoal]

    @Binding private var showingQuickAddExpense: Bool
    @State private var showingAddTransaction = false
    @State private var showingTransactions = false
    @State private var showingMonthlyBudget = false
    @State private var showingSettings = false
    @State private var showingBudgetEditor = false
    @State private var showingSavingsGoals = false
    @State private var createSavingsGoalOnAppear = false
    @State private var editingTransaction: Transaction?
    @State private var newAmountText = ""
    @State private var quickAmountText = ""
    @State private var budgetAmounts: [Category: String] = [:]
    @State private var newType: TransactionType = .expense
    @State private var newCategory: Category = .food
    @State private var quickCategory: Category = .food
    @AppStorage("lastQuickAddCategory") private var lastQuickAddCategoryRaw = Category.food.rawValue
    @AppStorage("rememberLastQuickAddCategory") private var rememberLastQuickAddCategory = false
    @AppStorage("quickAddHapticsEnabled") private var quickAddHapticsEnabled = true
    @AppStorage(AppPreferences.currencyCodeKey) private var currencyCode = AppPreferences.defaultCurrencyCode
    @State private var newDate = Date()
    @State private var newNote = ""
    @State private var receiptImageData: Data?
    @State private var hasLoadedReceiptState = false
    @State private var selectedReceiptItem: PhotosPickerItem?
    @State private var showingReceiptPreview = false
    @State private var quickNote = ""
    @State private var showingDeleteConfirmation = false
    @State private var showsCompactTitle = false
    @State private var feedbackMessage: String?
    @State private var feedbackDismissWorkItem: DispatchWorkItem?

    private var theme: AppTheme {
        themeManager.currentTheme
    }

    init(showingQuickAddExpense: Binding<Bool> = .constant(false)) {
        self._showingQuickAddExpense = showingQuickAddExpense
    }

    private var totalIncome: Double {
        transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    private var totalExpenses: Double {
        transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    private var balance: Double {
        totalIncome - totalExpenses
    }

    private var recentTransactions: [Transaction] {
        Array(transactions.prefix(5))
    }

    private var currencyStyle: FloatingPointFormatStyle<Double>.Currency {
        .currency(code: currencyCode)
    }

    private var quickAddCurrencySymbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = .autoupdatingCurrent
        return formatter.currencySymbol ?? currencyCode
    }

    private var expenseCategoryTotals: [(category: Category, amount: Double)] {
        let expenses = transactions.filter { $0.type == .expense }
        let grouped = Dictionary(grouping: expenses, by: \.category)
        return grouped
            .map { (category: $0.key, amount: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.amount > $1.amount }
    }

    private var currentMonthStart: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
    }

    private var currentMonthExpenseTotals: [Category: Double] {
        let expenses = transactions.filter {
            $0.type == .expense && $0.date >= currentMonthStart
        }
        return expenses.reduce(into: [:]) { partial, transaction in
            partial[transaction.category, default: 0] += transaction.amount
        }
    }

    private var currentMonthBudgetTargets: [Category: BudgetTarget] {
        Dictionary(
            uniqueKeysWithValues:
                budgetTargets
                .filter { Calendar.current.isDate($0.month, equalTo: Date(), toGranularity: .month) }
                .map { ($0.category, $0) }
        )
    }

    private var budgetItems: [BudgetSection.BudgetData] {
        Category.budgetCategories.map { category in
            BudgetSection.BudgetData(
                category: category,
                actual: currentMonthExpenseTotals[category, default: 0],
                target: currentMonthBudgetTargets[category]?.amount ?? 0
            )
        }
    }

    private var budgetCategoriesWithTargets: [BudgetSection.BudgetData] {
        budgetItems.filter { $0.target > 0 }
    }

    private var hasAnyBudgetTargets: Bool {
        !budgetTargets.isEmpty
    }

    private var totalBudgetTarget: Double {
        budgetCategoriesWithTargets.map { $0.target }.reduce(0, +)
    }

    private var totalBudgetActual: Double {
        budgetCategoriesWithTargets.map { $0.actual }.reduce(0, +)
    }

    private var overBudgetCategoryCount: Int {
        budgetCategoriesWithTargets.filter { $0.actual > $0.target }.count
    }

    private var nearBudgetCategoryCount: Int {
        budgetCategoriesWithTargets.filter { $0.actual > $0.target * 0.9 && $0.actual <= $0.target }.count
    }

    private var currentGuidedStep: GuidedStep {
        if transactions.isEmpty {
            return .firstTransaction
        }

        if !hasAnyBudgetTargets {
            return .budgetSetup
        }

        if savingsGoals.isEmpty {
            return .savingsGoal
        }

        return .allSet
    }

    private var budgetPreviewSummary: String {
        if currentGuidedStep == .firstTransaction {
            return "Add your first transaction to get started."
        }

        if !hasAnyBudgetTargets {
            return "Next: set your first budget."
        }

        if budgetCategoriesWithTargets.isEmpty {
            return "Set this month's budget to stay on track."
        }

        if overBudgetCategoryCount > 0 {
            return "Over budget in \(overBudgetCategoryCount) categories."
        }

        if nearBudgetCategoryCount > 0 {
            return "Near the limit in \(nearBudgetCategoryCount) categories."
        }

        return "On track across \(budgetCategoriesWithTargets.count) tracked categories."
    }

    private var budgetPreviewSubtitle: String {
        if currentGuidedStep == .firstTransaction {
            return "Start tracking"
        }

        if !hasAnyBudgetTargets {
            return "Create a budget"
        }

        if budgetCategoriesWithTargets.isEmpty {
            return "Set this month"
        }
        return "\(totalBudgetActual.formatted(currencyStyle)) of \(totalBudgetTarget.formatted(currencyStyle))"
    }

    private var quickAddDescription: String {
        switch currentGuidedStep {
        case .firstTransaction:
            return "Add your first transaction."
        case .budgetSetup:
            return "Keep tracking while you set a budget."
        case .savingsGoal:
            return "Keep logging while you start saving."
        case .allSet:
            return "Add an expense in seconds."
        }
    }

    private var savingsGoalsPreviewText: String {
        switch currentGuidedStep {
        case .firstTransaction:
            return "First add a transaction."
        case .budgetSetup:
            return "Next, set your first budget."
        case .savingsGoal:
            return "Next, create your first savings goal."
        case .allSet:
            return "Keep your savings goals moving."
        }
    }

    private var recentTransactionsEmptyText: String {
        switch currentGuidedStep {
        case .firstTransaction:
            return "Add your first transaction."
        case .budgetSetup:
            return "You're tracking now. Next, set your first budget."
        case .savingsGoal:
            return "Nice start. Next, create a savings goal."
        case .allSet:
            return "No recent transactions yet. Add one to keep things current."
        }
    }

    private var primaryActionTitle: String {
        switch currentGuidedStep {
        case .firstTransaction:
            return "Add your first transaction"
        case .budgetSetup:
            return "Good start. Set your first budget"
        case .savingsGoal:
            return "Create your first savings goal"
        case .allSet:
            return "You're all set"
        }
    }

    private var primaryActionMessage: String {
        switch currentGuidedStep {
        case .firstTransaction:
            return "Start tracking with one quick entry."
        case .budgetSetup:
            return "You're tracking now. Add category limits so the dashboard can guide you."
        case .savingsGoal:
            return "Give your money a clear destination."
        case .allSet:
            return "Keep logging, budgeting, and saving."
        }
    }

    private var primaryActionButtonTitle: String {
        switch currentGuidedStep {
        case .firstTransaction:
            return "Open Quick Add"
        case .budgetSetup:
            return "Set First Budget"
        case .savingsGoal:
            return "Create Savings Goal"
        case .allSet:
            return "Add Transaction"
        }
    }

    private var primaryActionBadgeText: String {
        switch currentGuidedStep {
        case .firstTransaction:
            return "Step 1 of 3"
        case .budgetSetup:
            return "Step 2 of 3"
        case .savingsGoal:
            return "Step 3 of 3"
        case .allSet:
            return "Complete"
        }
    }

    private var primaryActionBadgeIcon: String {
        switch currentGuidedStep {
        case .firstTransaction:
            return "bolt.fill"
        case .budgetSetup:
            return "chart.pie.fill"
        case .savingsGoal:
            return "flag.fill"
        case .allSet:
            return "checkmark.circle.fill"
        }
    }

    private var isBudgetSetupHighlighted: Bool {
        currentGuidedStep == .budgetSetup
    }

    private var activeSavingsGoalsCount: Int {
        savingsGoals.filter { !$0.isCompleted }.count
    }

    private var nearestSavingsGoal: SavingsGoal? {
        savingsGoals
            .filter { !$0.isCompleted }
            .sorted { $0.progress > $1.progress }
            .first
    }

    private var savingsGoalsPreviewCard: some View {
        Button {
            if currentGuidedStep == .savingsGoal && savingsGoals.isEmpty {
                openSavingsGoalCreation()
            } else {
                createSavingsGoalOnAppear = false
                showingSavingsGoals = true
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Savings Goals")
                        .font(.title3.weight(.bold))
                        .foregroundColor(theme.premiumCardTextPrimary)
                    if savingsGoals.isEmpty {
                        Text(savingsGoalsPreviewText)
                            .font(.caption)
                            .foregroundColor(theme.premiumCardTextSecondary)
                    } else {
                        Text("\(savingsGoals.count) goals · \(activeSavingsGoalsCount) active")
                            .font(.caption)
                            .foregroundColor(theme.premiumCardTextSecondary)
                        if let nearest = nearestSavingsGoal {
                            Text("Nearest: \(nearest.name) · \(Int(nearest.progress * 100))%")
                                .font(.caption2)
                                .foregroundColor(theme.premiumCardTextSecondary)
                        }
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(theme.premiumCardTextSecondary)
            }
            .padding(22)
            .premiumCard(cornerRadius: 24, emphasis: currentGuidedStep == .savingsGoal)
        }
        .buttonStyle(.plain)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 20) {
                        headerView
                        if currentGuidedStep != .allSet {
                            primaryActionCard
                        }
                        if let feedbackMessage {
                            feedbackBanner(message: feedbackMessage)
                        }
                        summaryView
                        monthlyBudgetPreviewCard
                        savingsGoalsPreviewCard
                        quickAddExpenseView
                        categoryBreakdownView
                        categoryChartView
                        recentTransactionsView
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                    .padding(.top, 8)
                }
                .coordinateSpace(name: "dashboardScroll")
                .background(theme.background.ignoresSafeArea())

                compactDashboardBar
                    .zIndex(1)
            }
            .toolbar {
#if os(iOS)
                if !showsCompactTitle {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        dashboardTopActions
                    }
                }
#else
                if !showsCompactTitle {
                    ToolbarItem {
                        dashboardTopActions
                    }
                }
#endif
            }
            .sheet(isPresented: $showingAddTransaction, onDismiss: {
                showingDeleteConfirmation = false
                resetForm()
            }) {
                transactionFormSheet(editing: nil)
            }
            .sheet(item: $editingTransaction, onDismiss: {
                showingDeleteConfirmation = false
                resetForm()
            }) { transaction in
                transactionFormSheet(editing: transaction)
            }
            .sheet(isPresented: $showingQuickAddExpense) {
                quickAddExpenseSheet
            }
            .sheet(isPresented: $showingBudgetEditor) {
                budgetEditorSheet
            }
            .navigationDestination(isPresented: $showingSettings) {
                SettingsView()
            }
            .navigationDestination(isPresented: $showingMonthlyBudget) {
                MonthlyBudgetView(
                    items: budgetItems,
                    hasTransactions: !transactions.isEmpty,
                    currencyStyle: currencyStyle,
                    onEdit: { prepareBudgetEditor() }
                )
            }
            .navigationDestination(isPresented: $showingSavingsGoals) {
                SavingsGoalsView(startsInEditor: createSavingsGoalOnAppear)
            }
            .navigationDestination(for: FinancialSummaryMode.self) { mode in
                FinancialSummaryView(
                    mode: mode,
                    transactions: transactions,
                    currencyStyle: currencyStyle,
                    onTapTransaction: { transaction in
                        editingTransaction = transaction
                        prepareForm(for: transaction)
                        showingDeleteConfirmation = false
                    },
                    deleteAction: deleteTransaction
                )
            }
            .navigationDestination(isPresented: $showingTransactions) {
                TransactionsView(
                    transactions: transactions,
                    currencyStyle: currencyStyle,
                    onTapTransaction: { transaction in
                        editingTransaction = transaction
                        prepareForm(for: transaction)
                        showingDeleteConfirmation = false
                    },
                    deleteAction: deleteTransaction
                )
            }
        }
        .onChange(of: quickCategory) {
            lastQuickAddCategoryRaw = quickCategory.rawValue
        }
        .onAppear {
            createSavingsGoalOnAppear = false
        }
        .onChange(of: currentGuidedStep) { oldValue, newValue in
            guard newValue.rawValue > oldValue.rawValue else { return }
            showFeedback(message: feedbackMessage(for: oldValue, next: newValue))
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 10) {
                Image("gyoza_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .offset(y: 1)

                Text("Gyoza Budget")
                    .font(.largeTitle.bold())
                    .foregroundColor(theme.textPrimary)
            }
            Text("Track income, expenses, and recent activity.")
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        updateCompactTitleVisibility(using: geo.frame(in: .global).minY)
                    }
                    .onChange(of: geo.frame(in: .global).minY) { _, minY in
                        updateCompactTitleVisibility(using: minY)
                    }
            }
        )
    }

    private var compactDashboardBar: some View {
        ZStack {
            Text("Gyoza Budget")
                .font(.headline.weight(.semibold))
                .foregroundColor(theme.textPrimary)

            HStack {
                Spacer()
                dashboardTopActions
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .frame(height: showsCompactTitle ? 36 : 0)
        .opacity(showsCompactTitle ? 1 : 0)
        .offset(y: showsCompactTitle ? 0 : -6)
        .clipped()
        .allowsHitTesting(showsCompactTitle)
        .animation(.easeInOut(duration: 0.2), value: showsCompactTitle)
    }

    private var dashboardTopActions: some View {
        HStack(spacing: 2) {
            settingsToolbarButton
            addTransactionToolbarButton
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            Capsule(style: .continuous)
                .fill(theme.cardBackground)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(theme.border, lineWidth: 0.5)
        )
    }

    private var settingsToolbarButton: some View {
        Button(action: {
            showingSettings = true
        }) {
            topActionIcon(systemName: "gearshape")
        }
        .buttonStyle(.plain)
    }

    private var addTransactionToolbarButton: some View {
        Button(action: {
            prepareForm(for: nil)
            showingDeleteConfirmation = false
            showingAddTransaction = true
        }) {
            topActionIcon(systemName: "plus")
        }
        .buttonStyle(.plain)
    }

    private func topActionIcon(systemName: String) -> some View {
        Image(systemName: systemName)
        .font(.system(size: 15, weight: .medium))
        .foregroundStyle(.primary)
        .frame(width: 32, height: 32)
        .contentShape(Circle())
    }

    private func updateCompactTitleVisibility(using minY: CGFloat) {
        let showThreshold: CGFloat = 56
        let hideThreshold: CGFloat = 68
        let shouldShowTitle = showsCompactTitle ? minY < hideThreshold : minY < showThreshold
        if shouldShowTitle != showsCompactTitle {
            withAnimation(.easeInOut(duration: 0.2)) {
                showsCompactTitle = shouldShowTitle
            }
        }
    }

    private var summaryView: some View {
        VStack(spacing: 14) {
            NavigationLink(value: FinancialSummaryMode.balance) {
                BalanceCardView(balance: balance, currencyStyle: currencyStyle)
            }
            .buttonStyle(.plain)

            HStack(spacing: 12) {
                NavigationLink(value: FinancialSummaryMode.income) {
                    MetricCardView(
                        title: "Income",
                        value: totalIncome,
                        currencyStyle: currencyStyle,
                        labelColor: theme.premiumCardTextSecondary
                    )
                }
                .buttonStyle(.plain)

                NavigationLink(value: FinancialSummaryMode.expenses) {
                    MetricCardView(
                        title: "Expenses",
                        value: totalExpenses,
                        currencyStyle: currencyStyle,
                        labelColor: theme.premiumCardTextSecondary
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var primaryActionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Label(primaryActionBadgeText, systemImage: primaryActionBadgeIcon)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(theme.premiumCardTextPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(theme.accent.opacity(isBudgetSetupHighlighted ? 0.24 : 0.18))
                    )

                if isBudgetSetupHighlighted {
                    Text("Recommended Next Step")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(theme.premiumCardTextSecondary)
                        .textCase(.uppercase)
                        .tracking(0.35)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(primaryActionTitle)
                    .font(.title3.weight(.bold))
                    .foregroundColor(theme.premiumCardTextPrimary)
                Text(primaryActionMessage)
                    .font(.subheadline)
                    .foregroundColor(theme.premiumCardTextSecondary)
            }

            Button(action: performPrimaryAction) {
                Text(primaryActionButtonTitle)
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(theme.accent)
                    .foregroundColor(theme.premiumOnAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(22)
        .premiumCard(cornerRadius: 24, emphasis: isBudgetSetupHighlighted)
    }

    private func feedbackBanner(message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(theme.premiumCardTextPrimary)
            Text(message)
                .font(.footnote.weight(.medium))
                .foregroundColor(theme.premiumCardTextPrimary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .premiumCard(cornerRadius: 18, glowEnabled: false)
    }

    private var monthlyBudgetPreviewCard: some View {
        Button {
            if currentGuidedStep == .budgetSetup {
                prepareBudgetEditor()
            } else {
                showingMonthlyBudget = true
            }
        } label: {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .font(.title2)
                    .foregroundColor(theme.accent)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Monthly Budget")
                        .font(.title3.weight(.bold))
                        .foregroundColor(theme.premiumCardTextPrimary)
                    Text(budgetPreviewSummary)
                        .font(.caption)
                        .foregroundColor(theme.premiumCardTextSecondary)
                        .lineLimit(2)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(budgetPreviewSubtitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(theme.premiumCardTextSecondary)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(theme.premiumCardTextSecondary)
                }
            }
            .padding(22)
            .premiumCard(cornerRadius: 24)
        }
        .buttonStyle(.plain)
    }

    private var quickAddExpenseView: some View {
        Button {
            showingQuickAddExpense = true
            resetQuickAddFields()
        } label: {
            HStack {
                Image(systemName: "bolt.circle.fill")
                    .font(.title2)
                    .foregroundColor(theme.accent)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Quick Add Expense")
                        .font(.title3.weight(.bold))
                        .foregroundColor(theme.premiumCardTextPrimary)
                    Text(quickAddDescription)
                        .font(.caption)
                        .foregroundColor(theme.premiumCardTextSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(theme.premiumCardTextSecondary)
            }
            .padding(22)
            .premiumCard(cornerRadius: 24, emphasis: currentGuidedStep == .firstTransaction)
        }
        .buttonStyle(.plain)
    }

    private var categoryBreakdownView: some View {
        CategoryBreakdownSection(
            totals: expenseCategoryTotals,
            currencyStyle: currencyStyle
        )
    }

    private var categoryChartView: some View {
        CategoryChartSection(
            totals: expenseCategoryTotals,
            currencyStyle: currencyStyle
        )
    }

    private var recentTransactionsView: some View {
        RecentTransactionsSection(
            transactions: recentTransactions,
            currencyStyle: currencyStyle,
            emptyStateText: recentTransactionsEmptyText,
            deleteAction: deleteTransaction,
            onTapTransaction: { transaction in
                editingTransaction = transaction
                prepareForm(for: transaction)
                showingDeleteConfirmation = false
            },
            onViewAll: {
                showingTransactions = true
            },
            onPrimaryAction: {
                openQuickAdd()
            }
        )
    }

    private func prepareBudgetEditor() {
        loadBudgetAmounts()
        showingBudgetEditor = true
    }

    private func loadBudgetAmounts() {
        budgetAmounts = Category.budgetCategories.reduce(into: [:]) { partial, category in
            let value = currentMonthBudgetTargets[category]?.amount ?? 0
            partial[category] = value > 0 ? String(format: "%.0f", value) : ""
        }
    }

    private func saveBudgetTargets() {
        let month = currentMonthStart

        for category in Category.budgetCategories {
            let text = budgetAmounts[category]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let amount = Double(text) ?? 0

            if let existing = currentMonthBudgetTargets[category] {
                if amount > 0 {
                    existing.amount = amount
                } else {
                    modelContext.delete(existing)
                }
            } else if amount > 0 {
                let target = BudgetTarget(category: category, amount: amount, month: month)
                modelContext.insert(target)
            }
        }

        saveContext()
        showingBudgetEditor = false
    }

    private var budgetEditorSheet: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(Category.budgetCategories) { category in
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(category.displayName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(theme.textPrimary)
                                if let amount = currentMonthBudgetTargets[category]?.amount, amount > 0 {
                                    Text("Current target: " + amount.formatted(currencyStyle))
                                        .font(.caption)
                                        .foregroundColor(theme.textSecondary)
                                }
                            }
                            Spacer()
                            TextField("0", text: Binding(
                                get: { budgetAmounts[category, default: ""] },
                                set: { budgetAmounts[category] = $0 }
                            ))
                            .font(.subheadline.weight(.semibold))
                            .multilineTextAlignment(.trailing)
#if os(iOS)
                            .keyboardType(.decimalPad)
#endif
                            .frame(width: 110)
                            .textFieldStyle(.roundedBorder)
                        }
                        .listRowBackground(theme.surface)
                    }
                } header: {
                    Text("Monthly budget targets")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(theme.textPrimary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.background)
            .navigationTitle("Budget Targets")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingBudgetEditor = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveBudgetTargets()
                    }
                }
            }
        }
    }

    private func deleteTransaction(_ transaction: Transaction) {
        withAnimation {
            modelContext.delete(transaction)
            saveContext()
        }
    }

    private func deleteCurrentTransaction(_ transaction: Transaction) {
        withAnimation {
            modelContext.delete(transaction)
            saveContext()
            editingTransaction = nil
            showingAddTransaction = false
            showingDeleteConfirmation = false
            resetForm()
        }
    }

    private func prepareForm(for transaction: Transaction?) {
        if let transaction {
            newAmountText = String(transaction.amount)
            newType = transaction.type
            newCategory = transaction.category
            newDate = transaction.date
            newNote = transaction.note ?? ""
            receiptImageData = transaction.receiptImageData
            hasLoadedReceiptState = true
        } else {
            resetForm()
        }
    }

    private func transactionFormSheet(editing transaction: Transaction?) -> some View {
        let resolvedReceiptImageData = resolvedReceiptImageData(for: transaction)
        let resolvedReceiptPreviewImage = resolvedReceiptImageData.flatMap(UIImage.init(data:))
        let hasResolvedReceipt = resolvedReceiptImageData != nil

        return NavigationStack {
            Form {
                Section(header: Text("Amount")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(theme.textPrimary)
                ) {
                    TextField("0.00", text: $newAmountText)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.leading)
                        .padding(.vertical, 10)
                        .listRowBackground(theme.surface)
#if os(iOS)
                        .keyboardType(.decimalPad)
#endif
                }

                Section(header: Text("Type")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(theme.textPrimary)
                ) {
                    Picker("Type", selection: $newType) {
                        ForEach(TransactionType.allCases) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(theme.accent)
                    .listRowBackground(theme.surface)
                }

                Section(header: Text("Category")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(theme.textPrimary)
                ) {
                    Picker("Category", selection: $newCategory) {
                        ForEach(Category.allCases) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                    .listRowBackground(theme.surface)
                }

                Section(header: Text("Date")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(theme.textPrimary)
                ) {
                    DatePicker("Transaction Date", selection: $newDate, displayedComponents: .date)
                        .listRowBackground(theme.surface)
                }

                Section(header: Text("Note")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(theme.textPrimary)
                ) {
                    TextField("Optional note", text: $newNote)
                        .textFieldStyle(.roundedBorder)
                        .listRowBackground(theme.surface)
                }

                if newType == .expense {
                    Section(header: Text("Receipt")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(theme.textPrimary)
                    ) {
                        VStack(alignment: .leading, spacing: 14) {
                            if let resolvedReceiptPreviewImage {
                                Button {
                                    showingReceiptPreview = true
                                } label: {
                                    Image(uiImage: resolvedReceiptPreviewImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 140)
                                        .frame(maxWidth: .infinity)
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }

                            HStack(spacing: 10) {
                                PhotosPicker(selection: $selectedReceiptItem, matching: .images, photoLibrary: .shared()) {
                                    Text(hasResolvedReceipt ? "Replace Photo" : "Attach Photo")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(theme.textPrimary)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .fill(theme.surface)
                                        )
                                }
                                .buttonStyle(.plain)

                                if hasResolvedReceipt {
                                    Button(role: .destructive) {
                                        receiptImageData = nil
                                        hasLoadedReceiptState = true
                                        selectedReceiptItem = nil
                                    } label: {
                                        Text("Remove")
                                            .font(.subheadline.weight(.semibold))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            Text(hasResolvedReceipt ? "Tap the preview to view it larger." : "Attach one receipt or photo for this expense.")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                        }
                        .listRowInsets(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16))
                        .listRowBackground(theme.surface)
                    }
                }

                if transaction != nil {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Text("Delete Transaction")
                        }
                    }
                    .listRowBackground(theme.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.background)
            .navigationTitle(transaction == nil ? "Add Transaction" : "Edit Transaction")
            .onChange(of: selectedReceiptItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let processedData = processedReceiptImageData(from: data) {
                        await MainActor.run {
                            receiptImageData = processedData
                            hasLoadedReceiptState = true
                        }
                    }
                    await MainActor.run {
                        selectedReceiptItem = nil
                    }
                }
            }
            .sheet(isPresented: $showingReceiptPreview) {
                NavigationStack {
                    ZStack {
                        theme.background
                            .ignoresSafeArea()

                        if let receiptPreviewImage {
                            Image(uiImage: receiptPreviewImage)
                                .resizable()
                                .scaledToFit()
                                .padding()
                        }
                    }
                    .navigationTitle("Receipt")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showingReceiptPreview = false
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingDeleteConfirmation = false
                        showingReceiptPreview = false
                        if transaction == nil {
                            showingAddTransaction = false
                        } else {
                            editingTransaction = nil
                        }
                        resetForm()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTransaction(editing: transaction)
                    }
                    .disabled(Double(newAmountText) == nil || newAmountText.isEmpty)
                }
            }
            .confirmationDialog("Delete this transaction?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                if let transaction {
                    Button("Delete Transaction", role: .destructive) {
                        deleteCurrentTransaction(transaction)
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func saveTransaction(editing transaction: Transaction?) {
        let trimmedAmountText = newAmountText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let amount = Double(trimmedAmountText), amount > 0 else { return }

        withAnimation {
            if let transaction {
                transaction.amount = amount
                transaction.type = newType
                transaction.category = newCategory
                transaction.date = newDate
                transaction.note = newNote.isEmpty ? nil : newNote
                transaction.receiptImageData = receiptImageData
            } else {
                let transaction = Transaction(
                    amount: amount,
                    type: newType,
                    category: newCategory,
                    date: newDate,
                    note: newNote.isEmpty ? nil : newNote,
                    receiptImageData: receiptImageData
                )
                modelContext.insert(transaction)
            }

            saveContext()
        }

        if transaction == nil {
            showingAddTransaction = false
        } else {
            editingTransaction = nil
        }
        showingDeleteConfirmation = false
        showingReceiptPreview = false
        resetForm()
    }

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }

    private func performPrimaryAction() {
        switch currentGuidedStep {
        case .firstTransaction:
            openQuickAdd()
        case .budgetSetup:
            prepareBudgetEditor()
        case .savingsGoal:
            openSavingsGoalCreation()
        case .allSet:
            openQuickAdd()
        }
    }

    private func openQuickAdd() {
        showingQuickAddExpense = true
        resetQuickAddFields()
    }

    private func openSavingsGoalCreation() {
        createSavingsGoalOnAppear = true
        showingSavingsGoals = true
    }

    private func feedbackMessage(for completedStep: GuidedStep, next step: GuidedStep) -> String {
        switch (completedStep, step) {
        case (.firstTransaction, .budgetSetup):
            return "Expense added. Next: set your first budget."
        case (.budgetSetup, .savingsGoal):
            return "Budget saved. Next: create a savings goal."
        case (.savingsGoal, .allSet):
            return "Savings goal created. You're all set."
        default:
            return "Step completed."
        }
    }

    private func showFeedback(message: String) {
        feedbackDismissWorkItem?.cancel()
        withAnimation(.easeInOut(duration: 0.2)) {
            feedbackMessage = message
        }

        let workItem = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.2)) {
                feedbackMessage = nil
            }
        }
        feedbackDismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5, execute: workItem)
    }

    private var quickAddExpenseSheet: some View {
        QuickAddExpenseSheet(
            isPresented: $showingQuickAddExpense,
            amountText: $quickAmountText,
            selectedCategory: $quickCategory,
            note: $quickNote,
            currencySymbol: quickAddCurrencySymbol,
            onSave: saveQuickExpense,
            onDismiss: resetQuickAddFields
        )
        .environmentObject(themeManager)
    }

    private func saveQuickExpense() {
        let trimmedAmountText = quickAmountText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let amount = Double(trimmedAmountText), amount > 0 else { return }

        withAnimation {
            let transaction = Transaction(
                amount: amount,
                type: .expense,
                category: quickCategory,
                date: Date(),
                note: quickNote.isEmpty ? nil : quickNote
            )
            modelContext.insert(transaction)
            saveContext()
#if os(iOS)
            if quickAddHapticsEnabled {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
#endif
        }

        showingQuickAddExpense = false
        resetQuickAddFields()
    }

    private func resetQuickAddFields() {
        quickAmountText = ""
        quickCategory = rememberLastQuickAddCategory ? Category(rawValue: lastQuickAddCategoryRaw) ?? .food : .food
        quickNote = ""
    }

    private func resetForm() {
        newAmountText = ""
        newType = .expense
        newCategory = .food
        newDate = Date()
        newNote = ""
        receiptImageData = nil
        hasLoadedReceiptState = false
        selectedReceiptItem = nil
        showingReceiptPreview = false
    }

    private var receiptPreviewImage: UIImage? {
        guard let effectiveReceiptImageData else { return nil }
        return UIImage(data: effectiveReceiptImageData)
    }

    private func resolvedReceiptImageData(for transaction: Transaction?) -> Data? {
        if hasLoadedReceiptState {
            return receiptImageData
        }
        return transaction?.receiptImageData ?? receiptImageData
    }

    private var effectiveReceiptImageData: Data? {
        if hasLoadedReceiptState {
            return receiptImageData
        }
        return editingTransaction?.receiptImageData
    }

    private func processedReceiptImageData(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }

        let maxDimension: CGFloat = 1600
        let longestSide = max(image.size.width, image.size.height)
        let scale = min(maxDimension / max(longestSide, 1), 1)
        let targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        return resizedImage.jpegData(compressionQuality: 0.75)
    }
}

private struct QuickAddExpenseSheet: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Binding private var isPresented: Bool
    @Binding private var amountText: String
    @Binding private var selectedCategory: Category
    @Binding private var note: String
    @FocusState private var amountFieldIsFocused: Bool

    let currencySymbol: String
    let onSave: () -> Void
    let onDismiss: () -> Void

    private var theme: AppTheme {
        themeManager.currentTheme
    }

    private var trimmedAmountText: String {
        amountText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isAmountValid: Bool {
        guard let amount = Double(trimmedAmountText) else { return false }
        return amount > 0
    }

    init(
        isPresented: Binding<Bool>,
        amountText: Binding<String>,
        selectedCategory: Binding<Category>,
        note: Binding<String>,
        currencySymbol: String,
        onSave: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self._isPresented = isPresented
        self._amountText = amountText
        self._selectedCategory = selectedCategory
        self._note = note
        self.currencySymbol = currencySymbol
        self.onSave = onSave
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quick Add Expense")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(theme.textPrimary)
                    Text("Fast capture for a single expense.")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                }
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(theme.textSecondary)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(theme.surface.opacity(0.6))
                        )
                }
            }

            VStack(spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(currencySymbol)
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                    TextField("0.00", text: $amountText)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .focused($amountFieldIsFocused)
#if os(iOS)
                        .keyboardType(.decimalPad)
                        .textContentType(.none)
                        .submitLabel(.done)
#endif
                }
                .padding(22)
                .frame(maxWidth: .infinity)
                .appPanelCard(cornerRadius: 24, emphasized: true)

                Text("Amount is the fastest input. Tap and enter the value.")
                    .font(.footnote)
                    .foregroundColor(theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: 14) {
                Text("Category")
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)

                let columns = [GridItem(.adaptive(minimum: 110), spacing: 10)]
                LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                    ForEach(Category.allCases) { category in
                        Button {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                selectedCategory = category
                            }
                        } label: {
                            Text(category.displayName)
                                .font(.subheadline.weight(.medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 14)
                                .frame(maxWidth: .infinity)
                                .background(
                                    Capsule()
                                        .fill(selectedCategory == category ? theme.accent : theme.surface)
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(selectedCategory == category ? theme.accent.opacity(0.12) : theme.border.opacity(0.8), lineWidth: 1)
                                )
                                .foregroundColor(selectedCategory == category ? theme.premiumOnAccent : theme.textPrimary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
            .appPanelCard(cornerRadius: 24)

            VStack(alignment: .leading, spacing: 10) {
                Text("Note")
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)
                TextField("Optional note", text: $note)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(20)
            .appPanelCard(cornerRadius: 24)

            Spacer()

            Button {
                onSave()
            } label: {
                Text("Save Expense")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(AppPrimaryButtonStyle())
            .opacity(isAmountValid ? 1 : 0.55)
            .disabled(!isAmountValid)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(theme.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 8)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeOut(duration: 0.22), value: isPresented)
        .onAppear {
            amountFieldIsFocused = true
        }
        .onDisappear {
            onDismiss()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager.shared)
        .modelContainer(for: [Transaction.self, BudgetTarget.self, SavingsGoal.self], inMemory: true)
}
