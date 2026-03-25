//
//  GroupDetailView.swift
//  Money Manager
//

import SwiftUI

struct GroupDetailView: View {
    @State private var viewModel: GroupDetailViewModel

    init(group: APIGroupWithDetails) {
        _viewModel = State(wrappedValue: GroupDetailViewModel(group: group))
    }

    var body: some View {
        VStack(spacing: 0) {
            GroupHeaderStats(
                total: viewModel.groupTotal,
                expenseCount: viewModel.expenses.count,
                memberCount: viewModel.members.count
            )
            .padding(.horizontal)
            .padding(.bottom, 8)

            Picker("Section", selection: $viewModel.selectedSection) {
                ForEach(GroupSection.allCases, id: \.self) { section in
                    Text(section.rawValue).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)

            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                ZStack(alignment: .bottomTrailing) {
                    sectionContent
                    fabView
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.group.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.showAddExpense) {
            AddExpenseView(
                mode: .shared(
                    group: viewModel.group,
                    members: viewModel.members
                ) { newExpense in
                    viewModel.expenseAdded(newExpense)
                }
            )
        }
        .sheet(isPresented: $viewModel.showSettlement) {
            RecordSettlementView(
                group: viewModel.group,
                members: viewModel.members,
                balances: viewModel.balances
            ) { settlement in
                viewModel.settlementRecorded(settlement)
            }
        }
        .sheet(isPresented: $viewModel.showAddMember) {
            AddMemberSheet(existingMembers: viewModel.members) { email in
                viewModel.addMember(email: email)
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.addMemberError != nil },
            set: { if !$0 { viewModel.addMemberError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.addMemberError ?? "")
        }
        .task {
            await viewModel.loadData()
        }
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch viewModel.selectedSection {
        case .expenses: expensesSection
        case .balances: balancesSection
        case .members:  membersSection
        }
    }

    @ViewBuilder
    private var fabView: some View {
        switch viewModel.selectedSection {
        case .expenses:
            FloatingActionButton(icon: "plus") { viewModel.showAddExpense = true }
        case .balances:
            if viewModel.hasUnsettledBalances {
                FloatingActionButton(icon: "arrow.left.arrow.right") { viewModel.showSettlement = true }
            }
        case .members:
            FloatingActionButton(icon: "person.badge.plus") { viewModel.showAddMember = true }
        }
    }

    private var expensesSection: some View {
        Group {
            if viewModel.expenses.isEmpty {
                EmptyStateView(icon: "receipt", title: "No Expenses", message: "Add the first expense to this group.")
            } else {
                List(viewModel.expenses) { expense in
                    GroupExpenseRow(expense: expense, members: viewModel.members)
                }
                .listStyle(.insetGrouped)
            }
        }
    }

    private var balancesSection: some View {
        Group {
            if viewModel.balances.isEmpty {
                EmptyStateView(icon: "scale.3d", title: "No Balances", message: "Balances will appear once expenses are added.")
            } else {
                List {
                    Section {
                        ForEach(viewModel.balances, id: \.user_id) { balance in
                            GroupBalanceRow(balance: balance, members: viewModel.members)
                        }
                    }
                    if viewModel.hasUnsettledBalances {
                        Section {
                            Button {
                                viewModel.showSettlement = true
                            } label: {
                                Label("Record a Settlement", systemImage: "arrow.left.arrow.right")
                                    .foregroundStyle(AppColors.accent)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }

    private var membersSection: some View {
        Group {
            if viewModel.members.isEmpty {
                EmptyStateView(icon: "person.3", title: "No Members", message: "Invite people to join this group.")
            } else {
                List {
                    Section {
                        ForEach(viewModel.members) { member in
                            GroupMemberRow(
                                member: member,
                                isAdmin: member.id == viewModel.group.created_by,
                                isPending: viewModel.isPending(member)
                            )
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
}

// MARK: - Header Stats

struct GroupHeaderStats: View {
    let total: Double
    let expenseCount: Int
    let memberCount: Int

    var body: some View {
        HStack(spacing: 0) {
            statCell(value: CurrencyFormatter.format(total, showDecimals: true), label: "Total")
            Divider().frame(height: 32)
            statCell(value: "\(expenseCount)", label: "Expenses")
            Divider().frame(height: 32)
            statCell(value: "\(memberCount)", label: "Members")
        }
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Expense Row

struct GroupExpenseRow: View {
    let expense: APIGroupExpense
    let members: [APIGroupMember]

    private var amount: Double { Double(expense.total_amount) ?? 0 }

    private var paidByName: String {
        members.first(where: { $0.id == expense.paid_by })?
            .email.components(separatedBy: "@").first?.capitalized ?? "Unknown"
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.description)
                    .font(.body)
                    .fontWeight(.medium)
                HStack(spacing: 4) {
                    Text("Paid by").foregroundStyle(.secondary)
                    Text(paidByName).foregroundStyle(AppColors.accent)
                }
                .font(.caption)
                Text(expense.created_at, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(CurrencyFormatter.format(amount, showDecimals: true))
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Balance Row

struct GroupBalanceRow: View {
    let balance: APIGroupBalance
    let members: [APIGroupMember]

    private var amount: Double { Double(balance.amount) ?? 0 }
    private var isOwed: Bool { amount < 0 }
    private var isSettled: Bool { amount == 0 }

    private var userName: String {
        members.first(where: { $0.id == balance.user_id })?
            .email.components(separatedBy: "@").first?.capitalized ?? "Unknown"
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isSettled ? AppColors.graySubtle : (isOwed ? AppColors.positive.opacity(0.12) : AppColors.expense.opacity(0.12)))
                    .frame(width: 40, height: 40)
                Image(systemName: isSettled ? "checkmark" : (isOwed ? "arrow.down.left" : "arrow.up.right"))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSettled ? .secondary : (isOwed ? AppColors.positive : AppColors.expense))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(userName).font(.body).fontWeight(.medium)
                Text(isOwed ? "is owed" : (isSettled ? "settled up" : "owes"))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if !isSettled {
                Text(CurrencyFormatter.format(abs(amount), showDecimals: true))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(isOwed ? AppColors.positive : AppColors.expense)
            } else {
                Text(CurrencyFormatter.format(0, showDecimals: true))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Member Row

struct GroupMemberRow: View {
    let member: APIGroupMember
    let isAdmin: Bool
    var isPending: Bool = false

    private var displayName: String {
        member.email.components(separatedBy: "@").first?.capitalized ?? member.email
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isPending ? AppColors.warning.opacity(0.12) : AppColors.accentSubtle)
                    .frame(width: 40, height: 40)
                if isPending {
                    Image(systemName: "clock")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.warning)
                } else {
                    Text(String(member.email.prefix(1)).uppercased())
                        .font(.headline)
                        .foregroundStyle(AppColors.accent)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(isPending ? .secondary : .primary)
                Text(member.email)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isPending {
                Text("Invited")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(AppColors.warning)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColors.warning.opacity(0.1))
                    .clipShape(.rect(cornerRadius: 6))
            } else if isAdmin {
                Text("Admin")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(AppColors.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColors.accentSubtle)
                    .clipShape(.rect(cornerRadius: 6))
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Add Member Sheet

struct AddMemberSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""

    let existingMembers: [APIGroupMember]
    var onAdd: (String) -> Void

    private var trimmed: String { email.trimmingCharacters(in: .whitespaces) }
    private var isValid: Bool { !trimmed.isEmpty && trimmed.contains("@") }
    private var isAlreadyMember: Bool {
        existingMembers.contains { $0.email.lowercased() == trimmed.lowercased() }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        TextField("e.g., friend@example.com", text: $email)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                    }
                    .padding(.vertical, 8)
                } footer: {
                    if isAlreadyMember {
                        Text("This user is already a member of the group.")
                            .foregroundStyle(AppColors.expense)
                    } else {
                        Text("An invite will be sent. They'll appear as \"Invited\" until they join.")
                    }
                }
            }
            .navigationTitle("Invite Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Invite") {
                        onAdd(trimmed)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid || isAlreadyMember)
                }
            }
        }
    }
}

// MARK: - Record Settlement View

struct RecordSettlementView: View {
    @Environment(\.dismiss) private var dismiss

    let group: APIGroupWithDetails
    let members: [APIGroupMember]
    let balances: [APIGroupBalance]
    var onSettle: (APISettlement) -> Void

    @State private var fromUserId: UUID?
    @State private var toUserId: UUID?
    @State private var amount = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    private var membersWhoOwe: [APIGroupMember] {
        let ids = balances.filter { (Double($0.amount) ?? 0) > 0 }.map(\.user_id)
        return members.filter { ids.contains($0.id) }
    }

    private var membersWhoAreOwed: [APIGroupMember] {
        let ids = balances.filter { (Double($0.amount) ?? 0) < 0 }.map(\.user_id)
        return members.filter { ids.contains($0.id) }
    }

    private var suggestedAmount: Double? {
        guard let fromId = fromUserId, let toId = toUserId else { return nil }
        let fromBal = abs(Double(balances.first(where: { $0.user_id == fromId })?.amount ?? "0") ?? 0)
        let toBal   = abs(Double(balances.first(where: { $0.user_id == toId })?.amount ?? "0") ?? 0)
        let suggested = min(fromBal, toBal)
        return suggested > 0 ? suggested : nil
    }

    private var isFormValid: Bool {
        guard let from = fromUserId, let to = toUserId,
              from != to,
              let amt = Double(amount), amt > 0 else { return false }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Who is paying?") {
                    if membersWhoOwe.isEmpty {
                        Text("No one owes anything").foregroundStyle(.secondary)
                    } else {
                        ForEach(membersWhoOwe) { member in
                            Button {
                                fromUserId = member.id
                                applySuggested()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(displayName(for: member)).foregroundStyle(.primary)
                                        let owes = Double(balances.first(where: { $0.user_id == member.id })?.amount ?? "0") ?? 0
                                        Text("owes \(CurrencyFormatter.format(owes, showDecimals: true))")
                                            .font(.caption).foregroundStyle(AppColors.expense)
                                    }
                                    Spacer()
                                    Image(systemName: fromUserId == member.id ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(fromUserId == member.id ? AppColors.accent : .secondary)
                                }
                            }
                        }
                    }
                }

                Section("Paying to?") {
                    if membersWhoAreOwed.isEmpty {
                        Text("No one is owed anything").foregroundStyle(.secondary)
                    } else {
                        ForEach(membersWhoAreOwed) { member in
                            Button {
                                toUserId = member.id
                                applySuggested()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(displayName(for: member)).foregroundStyle(.primary)
                                        let owed = abs(Double(balances.first(where: { $0.user_id == member.id })?.amount ?? "0") ?? 0)
                                        Text("is owed \(CurrencyFormatter.format(owed, showDecimals: true))")
                                            .font(.caption).foregroundStyle(AppColors.positive)
                                    }
                                    Spacer()
                                    Image(systemName: toUserId == member.id ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(toUserId == member.id ? AppColors.accent : .secondary)
                                }
                            }
                        }
                    }
                }

                Section("Amount") {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.title2)
                            .fontWeight(.semibold)
                        if let suggested = suggestedAmount {
                            Button {
                                amount = String(format: "%.2f", suggested)
                            } label: {
                                Text("Suggested: \(CurrencyFormatter.format(suggested, showDecimals: true))")
                                    .font(.caption)
                                    .foregroundStyle(AppColors.accent)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Record Settlement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Settle") { recordSettlement() }
                            .fontWeight(.semibold)
                            .disabled(!isFormValid || isLoading)
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func displayName(for member: APIGroupMember) -> String {
        member.email.components(separatedBy: "@").first?.capitalized ?? member.email
    }

    private func applySuggested() {
        if let suggested = suggestedAmount {
            amount = String(format: "%.2f", suggested)
        }
    }

    private func recordSettlement() {
        guard let from = fromUserId, let to = toUserId,
              let amt = Double(amount) else { return }
        isLoading = true
        Task {
            do {
                let request = APICreateSettlementRequest(
                    groupId: group.id,
                    fromUser: from,
                    toUser: to,
                    amount: String(format: "%.2f", amt)
                )
                let settlement = try await GroupService.shared.createSettlement(request)
                onSettle(settlement)
                dismiss()
            } catch {
                errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
}

// MARK: - Previews

#Preview("Group Detail") {
    let group = APIGroupWithDetails(
        id: UUID(),
        name: "Weekend Trip",
        created_by: UUID(),
        created_at: Date(),
        members: [],
        balances: []
    )
    NavigationStack {
        GroupDetailView(group: group)
    }
}
