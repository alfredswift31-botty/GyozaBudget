import SwiftUI
import SwiftData

/// Compares amounts at cent precision so accumulated Double error
/// can't leave a fully funded goal marked incomplete.
private func isFunded(current: Double, target: Double) -> Bool {
    (current * 100).rounded() >= (target * 100).rounded()
}

/// 0% renders as an empty bar; any visible progress gets a 12pt floor.
private func progressBarWidth(_ progress: Double, in totalWidth: CGFloat) -> CGFloat {
    guard progress > 0 else { return 0 }
    return max(min(CGFloat(progress), 1) * totalWidth, 12)
}

struct SavingsGoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager
    @Query(sort: [SortDescriptor(\Transaction.date, order: .reverse)]) private var transactions: [Transaction]
    @Query(sort: [SortDescriptor(\BudgetTarget.month, order: .reverse)]) private var budgetTargets: [BudgetTarget]
    @Query(sort: [SortDescriptor(\SavingsGoal.createdDate, order: .reverse)]) private var savingsGoals: [SavingsGoal]

    @State private var showingEditor = false
    @State private var editingGoal: SavingsGoal?
    @State private var name = ""
    @State private var targetText = ""
    @State private var showingSaveError = false
    @AppStorage(AppPreferences.currencyCodeKey) private var currencyCode = AppPreferences.defaultCurrencyCode
    let startsInEditor: Bool
    @State private var didTriggerInitialEditor = false

    init(startsInEditor: Bool = false) {
        self.startsInEditor = startsInEditor
    }

    private var theme: AppTheme {
        themeManager.currentTheme
    }

    private var currencyStyle: FloatingPointFormatStyle<Double>.Currency {
        .currency(code: currencyCode)
    }

    private var currencySymbol: String {
        AppPreferences.currencySymbol(for: currencyCode)
    }

    private var hasTransactions: Bool {
        !transactions.isEmpty
    }

    private var hasAnyBudgetTargets: Bool {
        !budgetTargets.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerView

                if savingsGoals.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 16) {
                        // Deleting lives in the goal detail view; .swipeActions
                        // only works inside a List, so it can't be used here.
                        ForEach(savingsGoals) { goal in
                            savingsGoalCard(goal)
                        }
                    }
                }
            }
            .padding()
        }
        .background(theme.background.ignoresSafeArea())
        .toolbar {
#if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    prepareEditor(for: nil)
                }) {
                    Label("New Goal", systemImage: "plus")
                }
                .accessibilityLabel("New Goal")
            }
#else
            ToolbarItem {
                Button(action: {
                    prepareEditor(for: nil)
                }) {
                    Label("New Goal", systemImage: "plus")
                }
                .accessibilityLabel("New Goal")
            }
#endif
        }
        .sheet(isPresented: $showingEditor) {
            savingsGoalEditor
                .environmentObject(themeManager)
        }
        .alert("Couldn't Save Changes", isPresented: $showingSaveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your latest change wasn't saved. Please try again.")
        }
        .onAppear {
            guard startsInEditor, !didTriggerInitialEditor else { return }
            didTriggerInitialEditor = true
            DispatchQueue.main.async {
                prepareEditor(for: nil)
            }
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Savings Goals")
                .font(.largeTitle.weight(.bold))
            Text("Track progress toward your savings pots.")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func savingsGoalCard(_ goal: SavingsGoal) -> some View {
        NavigationLink(destination: GoalDetailView(goal: goal, onEdit: { prepareEditor(for: $0) })) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(goal.name)
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.primary)
                        Text("\(goal.currentAmount.formatted(currencyStyle)) of \(goal.targetAmount.formatted(currencyStyle))")
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundColor(theme.textSecondary)
                    }
                    Spacer()
                    Text(goal.isCompleted ? "Completed" : goal.displayProgress)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(theme.textSecondary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(theme.progressBackground)
                        Capsule()
                            .fill(theme.accent)
                            .frame(width: progressBarWidth(goal.progress, in: geo.size.width), height: 10)
                    }
                }
                .frame(height: 10)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Progress")
                .accessibilityValue(goal.displayProgress)
            }
            .padding(18)
            .appPanelCard(cornerRadius: 16)
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label(emptyStateTitle, systemImage: "target")
        } description: {
            Text(emptyStateMessage)
        } actions: {
            Button(emptyStateCTA) {
                prepareEditor(for: nil)
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.accent)
        }
    }

    private var emptyStateTitle: String {
        if !hasTransactions {
            return "You can add a goal anytime."
        }

        if !hasAnyBudgetTargets {
            return "Savings comes after budgets."
        }

        return "Create your first savings goal."
    }

    private var emptyStateMessage: String {
        if !hasTransactions {
            return "Most people start with a transaction first, then add a budget and a savings goal."
        }

        if !hasAnyBudgetTargets {
            return "Your next setup step is a budget, but you can create a savings goal whenever you're ready."
        }

        return "Pick a target and start setting money aside with purpose."
    }

    private var emptyStateCTA: String {
        if !hasAnyBudgetTargets && hasTransactions {
            return "Create a Goal Anyway"
        }

        return "Create a Savings Goal"
    }

    private var savingsGoalEditor: some View {
        NavigationStack {
            Form {
                Section(header: Text("Goal details").font(.headline.weight(.semibold))) {
                    TextField("Goal name", text: $name)
                        .foregroundColor(.primary)
                    HStack(spacing: 10) {
                        Text(currencySymbol)
                            .foregroundColor(theme.textSecondary)
                        TextField("Target amount", text: $targetText)
                            .foregroundColor(.primary)
                            .keyboardType(.decimalPad)
                            .textContentType(.none)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.background)
            .navigationTitle(editingGoal == nil ? "New Savings Goal" : "Edit Savings Goal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingEditor = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveGoal()
                    }
                    .disabled(!isValidGoal)
                }
            }
        }
    }

    private func prepareEditor(for goal: SavingsGoal?) {
        editingGoal = goal
        if let goal {
            name = goal.name
            targetText = String(format: "%.2f", goal.targetAmount)
        } else {
            name = ""
            targetText = ""
        }
        showingEditor = true
    }

    private var isValidGoal: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return false }
        guard let target = AppPreferences.parseAmount(targetText), target > 0 else { return false }
        return true
    }

    private func saveGoal() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let target = AppPreferences.parseAmount(targetText), target > 0, !trimmedName.isEmpty else { return }

        if let goal = editingGoal {
            goal.name = trimmedName
            goal.targetAmount = target
            goal.isCompleted = isFunded(current: goal.currentAmount, target: target)
        } else {
            let goal = SavingsGoal(
                name: trimmedName,
                targetAmount: target,
                currentAmount: 0,
                createdDate: Date(),
                isCompleted: false
            )
            modelContext.insert(goal)
        }

        saveContext()
        showingEditor = false
    }

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            showingSaveError = true
        }
    }
}

private struct GoalDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @AppStorage(AppPreferences.currencyCodeKey) private var currencyCode = AppPreferences.defaultCurrencyCode

    let goal: SavingsGoal
    let onEdit: (SavingsGoal) -> Void

    @State private var showingDeleteConfirmation = false
    @State private var showingAddMoney = false
    @State private var addMoneyText = ""
    @State private var addMoneySliderValue = 0.0
    @State private var isSliderEditing = false
    @State private var showingAdjustAmount = false
    @State private var adjustAmountText = ""
    @State private var showingSaveError = false
    @FocusState private var addMoneyFieldIsFocused: Bool
    @FocusState private var adjustAmountFieldIsFocused: Bool

    private var theme: AppTheme {
        themeManager.currentTheme
    }

    private var currencyStyle: FloatingPointFormatStyle<Double>.Currency {
        .currency(code: currencyCode)
    }

    private var currencySymbol: String {
        AppPreferences.currencySymbol(for: currencyCode)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(goal.name)
                            .font(.title2.weight(.bold))
                            .foregroundColor(.primary)
                        Spacer()
                        Text(goal.isCompleted ? "Completed ✓" : "Active")
                            .font(.caption.weight(.semibold))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(goal.isCompleted ? theme.border.opacity(0.18) : theme.border.opacity(0.10))
                            )
                            .foregroundColor(goal.isCompleted ? .primary : .secondary)
                    }

                    VStack(spacing: 12) {
                        goalMetricRow(title: "Saved", value: goal.currentAmount)
                        goalMetricRow(title: "Target", value: goal.targetAmount)
                        if goal.currentAmount > goal.targetAmount {
                            goalMetricRow(title: "Over by", value: goal.currentAmount - goal.targetAmount)
                        } else {
                            goalMetricRow(title: "Remaining", value: max(goal.targetAmount - goal.currentAmount, 0))
                        }
                    }
                    .padding(18)
                    .appPanelCard(cornerRadius: 16)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Progress")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.primary)

                    HStack(spacing: 12) {
                        Text(goal.displayProgress)
                            .font(.title3.weight(.bold))
                            .monospacedDigit()
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(goal.currentAmount.formatted(currencyStyle)) of \(goal.targetAmount.formatted(currencyStyle))")
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundColor(theme.textSecondary)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(theme.progressBackground)
                                .frame(height: 12)
                            Capsule()
                                .fill(theme.accent)
                                .frame(width: progressBarWidth(goal.progress, in: geo.size.width), height: 12)
                                .shadow(color: Color.black.opacity(goal.isCompleted ? 0.08 : 0), radius: 2, x: 0, y: 1)
                        }
                    }
                    .frame(height: 12)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Progress")
                    .accessibilityValue(goal.displayProgress)
                }
                .padding(18)
                .appPanelCard(cornerRadius: 16)

                Button {
                    addMoneyText = ""
                    addMoneySliderValue = 0
                    showingAddMoney = true
                } label: {
                    Text("Add Money")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(theme.textPrimary)
                        .foregroundColor(theme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Button {
                    adjustAmountText = String(format: "%.2f", goal.currentAmount)
                    showingAdjustAmount = true
                } label: {
                    Text("Adjust Saved Amount")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(theme.card)
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Text("Delete Goal")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.red)
                        .background(theme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding()
        }
        .background(theme.background.ignoresSafeArea())
        .navigationTitle("Goal details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Edit") {
                    onEdit(goal)
                }
            }
        }
        .sheet(isPresented: $showingAddMoney) {
            NavigationStack {
                addMoneySheet
                    .navigationTitle("Add Money")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingAddMoney = false
                                addMoneyText = ""
                            }
                        }
                    }
            }
            .environmentObject(themeManager)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingAdjustAmount) {
            NavigationStack {
                adjustAmountSheet
                    .navigationTitle("Adjust Saved Amount")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingAdjustAmount = false
                                adjustAmountText = ""
                            }
                        }
                    }
            }
            .environmentObject(themeManager)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .alert("Couldn't Save Changes", isPresented: $showingSaveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your latest change wasn't saved. Please try again.")
        }
        .confirmationDialog("Delete this savings goal?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete Goal", role: .destructive) {
                // Pop the detail view before deleting so it never renders
                // against a deleted model object.
                dismiss()
                DispatchQueue.main.async {
                    deleteGoal(goal)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func goalMetricRow(title: String, value: Double) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
            Spacer()
            Text(value.formatted(currencyStyle))
                .font(.headline.weight(.semibold))
                .monospacedDigit()
                .foregroundColor(.primary)
        }
    }

    /// Single source of truth for the entered amount: both the preview
    /// rows and Save read this, so they can never disagree.
    private var parsedAddAmount: Double {
        AppPreferences.parseAmount(addMoneyText) ?? 0
    }

    private var addMoneySheet: some View {
        let enteredAmount = parsedAddAmount
        let newTotal = goal.currentAmount + enteredAmount
        let previewProgress = min(max(goal.targetAmount > 0 ? newTotal / goal.targetAmount : 0, 0), 1)
        let remaining = max(goal.targetAmount - goal.currentAmount, 0)
        let sliderMaximum = goal.currentAmount >= goal.targetAmount
            ? max(goal.targetAmount * 0.5, 50)
            : max(remaining * 1.5, 10)

        return VStack(spacing: 20) {
            VStack(spacing: 18) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(currencySymbol)
                        .font(.system(.title, design: .rounded, weight: .semibold))
                        .foregroundColor(.primary)
                    TextField("0.00", text: $addMoneyText)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .monospacedDigit()
                        .multilineTextAlignment(.center)
                        .focused($addMoneyFieldIsFocused)
                        .onChange(of: addMoneyText) {
                            if let value = AppPreferences.parseAmount(addMoneyText) {
                                addMoneySliderValue = min(max(value, 0), sliderMaximum)
                            }
                        }
#if os(iOS)
                        .keyboardType(.decimalPad)
                        .textContentType(.none)
                        .submitLabel(.done)
#endif
                }
                .padding(22)
                .frame(maxWidth: .infinity)
                .appPanelCard(cornerRadius: 16)

                Slider(
                    value: $addMoneySliderValue,
                    in: 0...sliderMaximum,
                    step: 1,
                    onEditingChanged: { isSliderEditing = $0 }
                )
                    .tint(theme.accent)
                    .labelsHidden()
                    .frame(height: 28)
                    .padding(.horizontal, 4)
                    .padding(.top, 4)
                    .padding(.bottom, 2)
                    .onChange(of: addMoneySliderValue) {
                        // Only mirror slider → text while the user is dragging
                        // the slider; otherwise typing "15" gets rewritten to
                        // "1.00" mid-keystroke by this feedback loop.
                        guard isSliderEditing else { return }
                        addMoneyText = String(format: "%.2f", addMoneySliderValue)
                    }

                Text("Slide to add up to \(sliderMaximum.formatted(currencyStyle))")
                    .font(.footnote)
                    .foregroundColor(theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 8) {
                    previewRow(title: "Current saved", value: goal.currentAmount)
                    previewRow(title: "Adding", value: enteredAmount)
                    previewRow(title: "New total", value: newTotal)

                    HStack {
                        Text("Updated progress")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%d%%", Int(previewProgress * 100)))
                            .font(.footnote.weight(.semibold))
                            .monospacedDigit()
                            .foregroundColor(.primary)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(theme.progressBackground)
                                .frame(height: 10)
                            Capsule()
                                .fill(theme.accent)
                                .frame(width: progressBarWidth(previewProgress, in: geo.size.width), height: 10)
                        }
                    }
                    .frame(height: 10)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Updated progress")
                    .accessibilityValue("\(Int(previewProgress * 100)) percent")
                }
                .padding(18)
                .appPanelCard(cornerRadius: 16)
            }

            Spacer()

            Button {
                saveAddMoney()
            } label: {
                Text("Save")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isAddMoneyAmountValid ? theme.textPrimary : theme.border)
                    .foregroundColor(theme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(!isAddMoneyAmountValid)
        }
        .padding(20)
        .onAppear {
            addMoneyFieldIsFocused = true
        }
    }

    private func previewRow(title: String, value: Double) -> some View {
        HStack {
            Text(title)
                .font(.footnote)
                .foregroundColor(.secondary)
            Spacer()
            Text(value.formatted(currencyStyle))
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundColor(.primary)
        }
    }

    private var adjustAmountSheet: some View {
        VStack(spacing: 20) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(currencySymbol)
                    .font(.system(.title, design: .rounded, weight: .semibold))
                    .foregroundColor(.primary)
                TextField("0.00", text: $adjustAmountText)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .multilineTextAlignment(.center)
                    .focused($adjustAmountFieldIsFocused)
#if os(iOS)
                    .keyboardType(.decimalPad)
                    .textContentType(.none)
                    .submitLabel(.done)
#endif
            }
            .padding(22)
            .frame(maxWidth: .infinity)
            .appPanelCard(cornerRadius: 16)

            Spacer()

            Button {
                saveAdjustedAmount()
            } label: {
                Text("Save")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background((AppPreferences.parseAmount(adjustAmountText) ?? -1) >= 0 ? theme.textPrimary : theme.border)
                    .foregroundColor(theme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled((AppPreferences.parseAmount(adjustAmountText) ?? -1) < 0)
        }
        .padding(20)
        .onAppear {
            adjustAmountFieldIsFocused = true
        }
    }

    private var isAddMoneyAmountValid: Bool {
        parsedAddAmount > 0
    }

    private func saveAddMoney() {
        let amount = parsedAddAmount
        guard amount > 0 else { return }
        withAnimation {
            goal.currentAmount += amount
            goal.isCompleted = isFunded(current: goal.currentAmount, target: goal.targetAmount)
            saveContext()
        }
        showingAddMoney = false
        addMoneyText = ""
        addMoneySliderValue = 0
    }

    private func saveAdjustedAmount() {
        guard let amount = AppPreferences.parseAmount(adjustAmountText), amount >= 0 else { return }
        withAnimation {
            goal.currentAmount = amount
            goal.isCompleted = isFunded(current: goal.currentAmount, target: goal.targetAmount)
            saveContext()
        }
        showingAdjustAmount = false
        adjustAmountText = ""
    }

    private func deleteGoal(_ goal: SavingsGoal) {
        withAnimation {
            modelContext.delete(goal)
            saveContext()
        }
    }

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            showingSaveError = true
        }
    }
}

#Preview {
    NavigationStack {
        SavingsGoalsView()
    }
    .environmentObject(ThemeManager.shared)
}
