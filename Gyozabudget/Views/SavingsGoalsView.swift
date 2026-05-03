import SwiftUI
import SwiftData

struct SavingsGoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: [SortDescriptor(\Transaction.date, order: .reverse)]) private var transactions: [Transaction]
    @Query(sort: [SortDescriptor(\BudgetTarget.month, order: .reverse)]) private var budgetTargets: [BudgetTarget]
    @Query(sort: [SortDescriptor(\SavingsGoal.createdDate, order: .reverse)]) private var savingsGoals: [SavingsGoal]

    @State private var showingEditor = false
    @State private var editingGoal: SavingsGoal?
    @State private var name = ""
    @State private var targetText = ""
    @State private var showingDeleteConfirmation = false
    @State private var showingAddMoney = false
    @State private var addMoneyText = ""
    @State private var addMoneySliderValue = 0.0
    @State private var showingAdjustAmount = false
    @State private var adjustAmountText = ""
    @FocusState private var addMoneyFieldIsFocused: Bool
    @FocusState private var adjustAmountFieldIsFocused: Bool
    @AppStorage(AppPreferences.currencyCodeKey) private var currencyCode = AppPreferences.defaultCurrencyCode
    let startsInEditor: Bool
    @State private var didTriggerInitialEditor = false

    init(startsInEditor: Bool = false) {
        self.startsInEditor = startsInEditor
    }

    private var currencyStyle: FloatingPointFormatStyle<Double>.Currency {
        .currency(code: currencyCode)
    }

    private var currencySymbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.currencySymbol ?? "$"
    }

    private var completedGoals: [SavingsGoal] {
        savingsGoals.filter { $0.isCompleted }
    }

    private var activeGoals: [SavingsGoal] {
        savingsGoals.filter { !$0.isCompleted }
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
                        ForEach(savingsGoals) { goal in
                            savingsGoalCard(goal)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteGoal(goal)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color.appBackground(for: colorScheme).ignoresSafeArea())
        .toolbar {
#if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    prepareEditor(for: nil)
                }) {
                    Label("New Goal", systemImage: "plus")
                }
            }
#else
            ToolbarItem {
                Button(action: {
                    prepareEditor(for: nil)
                }) {
                    Label("New Goal", systemImage: "plus")
                }
            }
#endif
        }
        .sheet(isPresented: $showingEditor) {
            savingsGoalEditor
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
                .foregroundColor(Color.appSecondaryText(for: colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func savingsGoalCard(_ goal: SavingsGoal) -> some View {
        NavigationLink(destination: goalDetailView(goal)) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(goal.name)
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.primary)
                        Text("\(goal.currentAmount.formatted(currencyStyle)) of \(goal.targetAmount.formatted(currencyStyle))")
                            .font(.caption)
                            .foregroundColor(Color.appSecondaryText(for: colorScheme))
                    }
                    Spacer()
                    Text(goal.isCompleted ? "Completed" : goal.displayProgress)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(Color.appSecondaryText(for: colorScheme))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.appProgressBackground(for: colorScheme))
                        Capsule()
                            .fill(Color.appProgressFill(for: colorScheme))
                            .frame(width: max(min(CGFloat(goal.progress), 1) * geo.size.width, 12), height: 10)
                    }
                }
                .frame(height: 10)
            }
            .padding(18)
            .appPanelCard(cornerRadius: 24)
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(emptyStateTitle)
                .font(.title3.weight(.semibold))
                .foregroundColor(.primary)
            Text(emptyStateMessage)
                .font(.subheadline)
                .foregroundColor(Color.appSecondaryText(for: colorScheme))
            Button(action: {
                prepareEditor(for: nil)
            }) {
                Text(emptyStateCTA)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(AppPrimaryButtonStyle())
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appPanelCard(cornerRadius: 24)
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

    private func goalDetailView(_ goal: SavingsGoal) -> some View {
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
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(goal.isCompleted ? Color.appBorder(for: colorScheme).opacity(0.18) : Color.appBorder(for: colorScheme).opacity(0.10))
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
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.appSurface(for: colorScheme))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.appBorder(for: colorScheme), lineWidth: 1)
                    )
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Progress")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.primary)

                    HStack(spacing: 12) {
                        Text(goal.displayProgress)
                            .font(.title3.weight(.bold))
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(goal.currentAmount.formatted(currencyStyle)) of \(goal.targetAmount.formatted(currencyStyle))")
                            .font(.caption)
                            .foregroundColor(Color.appSecondaryText(for: colorScheme))
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.appProgressBackground(for: colorScheme))
                                .frame(height: 12)
                            Capsule()
                                .fill(Color.appProgressFill(for: colorScheme))
                                .frame(width: max(min(CGFloat(goal.progress), 1) * geo.size.width, 12), height: 12)
                                .shadow(color: Color.black.opacity(goal.isCompleted ? 0.08 : 0), radius: 2, x: 0, y: 1)
                        }
                    }
                    .frame(height: 12)
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.appSurface(for: colorScheme))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.appBorder(for: colorScheme), lineWidth: 1)
                )

                Button {
                    addMoneyText = ""
                    addMoneySliderValue = 0
                    showingAddMoney = true
                } label: {
                    Text("Add Money")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appPrimaryText(for: colorScheme))
                        .foregroundColor(Color.appBackground(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                Button {
                    adjustAmountText = String(format: "%.2f", goal.currentAmount)
                    showingAdjustAmount = true
                } label: {
                    Text("Adjust Saved Amount")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appSurfaceAlt(for: colorScheme))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
            .padding()
        }
        .background(Color.appBackground(for: colorScheme).ignoresSafeArea())
        .navigationTitle("Goal details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Edit") {
                    prepareEditor(for: goal)
                }
            }
        }
        .sheet(isPresented: $showingAddMoney) {
            addMoneySheet(for: goal)
        }
        .sheet(isPresented: $showingAdjustAmount) {
            adjustAmountSheet(for: goal)
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
                .foregroundColor(.primary)
        }
    }

    private func addMoneySheet(for goal: SavingsGoal) -> some View {
        let enteredAmount = Double(addMoneyText) ?? addMoneySliderValue
        let newTotal = goal.currentAmount + enteredAmount
        let previewProgress = min(max(goal.targetAmount > 0 ? newTotal / goal.targetAmount : 0, 0), 1)
        let remaining = max(goal.targetAmount - goal.currentAmount, 0)
        let sliderMaximum = goal.currentAmount >= goal.targetAmount
            ? max(goal.targetAmount * 0.5, 50)
            : max(remaining * 1.5, 10)

        return VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Add Money")
                        .font(.title2.bold())
                    Text("Choose the amount to add and confirm.")
                        .font(.subheadline)
                        .foregroundColor(Color.appSecondaryText(for: colorScheme))
                }
                Spacer()
                Button {
                    showingAddMoney = false
                    addMoneyText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color.appSecondaryText(for: colorScheme))
                }
            }

            VStack(spacing: 18) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(currencySymbol)
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    TextField("0.00", text: $addMoneyText)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .focused($addMoneyFieldIsFocused)
                        .onChange(of: addMoneyText) {
                            if let value = Double(addMoneyText) {
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
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.appSurface(for: colorScheme))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.appBorder(for: colorScheme), lineWidth: 1)
                )

                Slider(value: $addMoneySliderValue, in: 0...sliderMaximum, step: 1)
                    .tint(Color.appAccent(for: colorScheme))
                    .labelsHidden()
                    .frame(height: 28)
                    .padding(.horizontal, 4)
                    .padding(.top, 4)
                    .padding(.bottom, 2)
                    .onChange(of: addMoneySliderValue) {
                        addMoneyText = String(format: "%.2f", addMoneySliderValue)
                    }

                Text("Slide to add up to \(sliderMaximum.formatted(currencyStyle))")
                    .font(.footnote)
                    .foregroundColor(Color.appSecondaryText(for: colorScheme))
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
                            .foregroundColor(.primary)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.appProgressBackground(for: colorScheme))
                                .frame(height: 10)
                            Capsule()
                                .fill(Color.appProgressFill(for: colorScheme))
                                .frame(width: max(min(CGFloat(previewProgress), 1) * geo.size.width, 12), height: 10)
                        }
                    }
                    .frame(height: 10)
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.appSurface(for: colorScheme))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.appBorder(for: colorScheme), lineWidth: 1)
                )
            }

            Spacer()

            Button {
                saveAddMoney(for: goal)
            } label: {
                Text("Save")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isAddMoneyAmountValid ? Color.appPrimaryText(for: colorScheme) : Color.appBorder(for: colorScheme))
                    .foregroundColor(Color.appBackground(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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
                .foregroundColor(.primary)
        }
    }

    private func adjustAmountSheet(for goal: SavingsGoal) -> some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Adjust Saved Amount")
                        .font(.title2.bold())
                    Text("Correct the current savings total.")
                        .font(.subheadline)
                        .foregroundColor(Color.appSecondaryText(for: colorScheme))
                }
                Spacer()
                Button {
                    showingAdjustAmount = false
                    adjustAmountText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color.appSecondaryText(for: colorScheme))
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(currencySymbol)
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                TextField("0.00", text: $adjustAmountText)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
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
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.appSurface(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.appBorder(for: colorScheme), lineWidth: 1)
            )

            Spacer()

            Button {
                saveAdjustedAmount(for: goal)
            } label: {
                Text("Save")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background((Double(adjustAmountText) ?? -1) >= 0 ? Color.appPrimaryText(for: colorScheme) : Color.appBorder(for: colorScheme))
                    .foregroundColor(Color.appBackground(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .disabled((Double(adjustAmountText) ?? -1) < 0)
        }
        .padding(20)
        .onAppear {
            adjustAmountFieldIsFocused = true
        }
    }

    private var isAddMoneyAmountValid: Bool {
        guard let amount = Double(addMoneyText) else { return false }
        return amount > 0
    }

    private func saveAddMoney(for goal: SavingsGoal) {
        guard let amount = Double(addMoneyText), amount > 0 else { return }
        withAnimation {
            goal.currentAmount += amount
            goal.isCompleted = goal.currentAmount >= goal.targetAmount
            saveContext()
        }
        showingAddMoney = false
        addMoneyText = ""
        addMoneySliderValue = 0
    }

    private func saveAdjustedAmount(for goal: SavingsGoal) {
        guard let amount = Double(adjustAmountText), amount >= 0 else { return }
        withAnimation {
            goal.currentAmount = amount
            goal.isCompleted = goal.currentAmount >= goal.targetAmount
            saveContext()
        }
        showingAdjustAmount = false
        adjustAmountText = ""
    }

    private var savingsGoalEditor: some View {
        NavigationStack {
            Form {
                Section(header: Text("Goal details").font(.headline.weight(.semibold))) {
                    TextField("Goal name", text: $name)
                        .foregroundColor(.primary)
                    HStack(spacing: 10) {
                        Text(currencySymbol)
                            .foregroundColor(Color.appSecondaryText(for: colorScheme))
                        TextField("Target amount", text: $targetText)
                            .foregroundColor(.primary)
                            .keyboardType(.decimalPad)
                            .textContentType(.none)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground(for: colorScheme))
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
        guard let target = Double(targetText), target > 0 else { return false }
        return true
    }

    private func saveGoal() {
        guard let target = Double(targetText) else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if let goal = editingGoal {
            goal.name = trimmedName
            goal.targetAmount = target
            goal.isCompleted = goal.currentAmount >= target
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
            print("Failed to save savings goal: \(error)")
        }
    }
}

#Preview {
    SavingsGoalsView()
}
