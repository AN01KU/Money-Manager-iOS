import SwiftUI

struct GroupDetailView: View {
    let group: SplitGroup
    var initialExpenses: [SharedExpense]?
    var initialBalances: [UserBalance]?
    var initialMembers: [APIUser]?
    
    @StateObject private var viewModel: GroupDetailViewModel
    
    init(group: SplitGroup,
         initialExpenses: [SharedExpense]? = nil,
         initialBalances: [UserBalance]? = nil,
         initialMembers: [APIUser]? = nil) {
        self.group = group
        self.initialExpenses = initialExpenses
        self.initialBalances = initialBalances
        self.initialMembers = initialMembers
        _viewModel = StateObject(wrappedValue: GroupDetailViewModel(
            group: group,
            initialExpenses: initialExpenses,
            initialBalances: initialBalances,
            initialMembers: initialMembers
        ))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            groupHeader
            
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
                    switch viewModel.selectedSection {
                    case .expenses:
                        expensesSection
                    case .balances:
                        balancesSection
                    case .members:
                        membersSection
                    }
                    
                    if viewModel.selectedSection == .expenses {
                        FloatingActionButton(icon: "plus") {
                            viewModel.showAddExpense = true
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                    }
                    
                    if viewModel.selectedSection == .balances && viewModel.hasUnsettledBalances {
                        FloatingActionButton(icon: "arrow.left.arrow.right") {
                            viewModel.showSettlement = true
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.showAddExpense) {
            AddExpenseView(mode: .shared(group: group, members: viewModel.members) { newExpense in
                viewModel.addExpense(newExpense)
            })
        }
        .sheet(isPresented: $viewModel.showSettlement) {
            RecordSettlementView(group: group, members: viewModel.members, balances: viewModel.balances) { _ in
                viewModel.recalculateBalances()
            }
        }
        .task {
            await viewModel.loadData()
        }
    }
    
    private var groupHeader: some View {
        HStack(spacing: 16) {
            VStack(spacing: 2) {
                Text(CurrencyFormatter.format(viewModel.groupTotal))
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                Text("Total")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 32)
            
            VStack(spacing: 2) {
                Text("\(viewModel.expenses.count)")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                Text("Expenses")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 32)
            
            VStack(spacing: 2) {
                Text("\(viewModel.members.count)")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                Text("Members")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    private var expensesSection: some View {
        Group {
            if viewModel.expenses.isEmpty {
                EmptyStateView(
                    icon: "receipt",
                    title: "No expenses yet",
                    message: "Tap + to add a shared expense"
                )
            } else {
                List(viewModel.expenses) { expense in
                    ExpenseRow(expense: expense, members: viewModel.members)
                }
                .listStyle(.insetGrouped)
            }
        }
    }
    
    private var balancesSection: some View {
        Group {
            if viewModel.balances.isEmpty {
                EmptyStateView(
                    icon: "scale.3d",
                    title: "No balances",
                    message: "Add expenses to see who owes what"
                )
            } else {
                List {
                    Section {
                        ForEach(viewModel.balances, id: \.userId) { balance in
                            BalanceRow(balance: balance, members: viewModel.members)
                        }
                    }
                    
                    if viewModel.hasUnsettledBalances {
                        Section {
                            Button {
                                viewModel.showSettlement = true
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.left.arrow.right")
                                    Text("Record a Settlement")
                                }
                                .foregroundColor(.teal)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
    
    private var membersSection: some View {
        List {
            Section {
                ForEach(viewModel.members) { member in
                    MemberRow(member: member, isAdmin: member.id == group.createdBy)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Row Components

struct MemberRow: View {
    let member: APIUser
    let isAdmin: Bool
    
    private var displayName: String {
        member.email.components(separatedBy: "@").first?.capitalized ?? member.email
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.teal.opacity(0.12))
                    .frame(width: 40, height: 40)
                
                Text(String(member.email.prefix(1)).uppercased())
                    .font(.headline)
                    .foregroundColor(.teal)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.body)
                    .fontWeight(.medium)
                Text(member.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isAdmin {
                Text("Admin")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.teal)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.teal.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding(.vertical, 2)
    }
}

struct ExpenseRow: View {
    let expense: SharedExpense
    var members: [APIUser] = []
    
    private var amount: Double {
        Double(expense.totalAmount) ?? 0
    }
    
    private var paidByName: String {
        members.first(where: { $0.id == expense.paidBy })?.email
            .components(separatedBy: "@").first?.capitalized ?? "Unknown"
    }
    
    private var splitCount: Int {
        expense.splits?.count ?? 0
    }
    
    private var formattedDate: String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = iso.date(from: expense.createdAt) ?? ISO8601DateFormatter().date(from: expense.createdAt)
        guard let date else { return expense.createdAt }
        let display = DateFormatter()
        display.dateStyle = .medium
        return display.string(from: date)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.description)
                    .font(.body)
                    .fontWeight(.medium)
                
                HStack(spacing: 4) {
                    Text("Paid by")
                        .foregroundColor(.secondary)
                    Text(paidByName)
                        .foregroundColor(.teal)
                }
                .font(.caption)
                
                HStack(spacing: 8) {
                    Text(formattedDate)
                    if splitCount > 0 {
                        Text("·")
                        Text("Split \(splitCount) ways")
                    }
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(CurrencyFormatter.format(amount))
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 4)
    }
}

struct BalanceRow: View {
    let balance: UserBalance
    var members: [APIUser] = []
    
    private var amount: Double {
        Double(balance.amount) ?? 0
    }
    
    private var userName: String {
        members.first(where: { $0.id == balance.userId })?.email
            .components(separatedBy: "@").first?.capitalized ?? "Unknown"
    }
    
    private var isOwed: Bool {
        amount < 0
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isOwed ? Color.green.opacity(0.12) : (amount == 0 ? Color.gray.opacity(0.12) : Color.red.opacity(0.12)))
                    .frame(width: 40, height: 40)
                
                Image(systemName: isOwed ? "arrow.down.left" : (amount == 0 ? "checkmark" : "arrow.up.right"))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isOwed ? .green : (amount == 0 ? .gray : .red))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(userName)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(isOwed ? "is owed" : (amount == 0 ? "settled up" : "owes"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if amount != 0 {
                Text(CurrencyFormatter.format(abs(amount), showDecimals: true))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isOwed ? .green : .red)
            } else {
                Text("₹0")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Previews

#Preview("With Expenses") {
    let group = TestData.testGroups[0]
    NavigationStack {
        GroupDetailView(
            group: group,
            initialExpenses: TestData.testSharedExpenses[group.id] ?? [],
            initialBalances: TestData.testBalances[group.id] ?? [],
            initialMembers: TestData.testGroupMembers[group.id] ?? []
        )
    }
}

#Preview("Empty Group") {
    NavigationStack {
        GroupDetailView(
            group: SplitGroup(id: UUID(), name: "New Trip", createdBy: UUID(), createdAt: ISO8601DateFormatter().string(from: Date())),
            initialExpenses: [],
            initialBalances: [],
            initialMembers: []
        )
    }
}

#Preview("All Settled") {
    let group = TestData.testGroups[0]
    let members = TestData.testGroupMembers[group.id] ?? []
    let settledBalances = members.map { UserBalance(userId: $0.id, amount: "0.00") }
    NavigationStack {
        GroupDetailView(
            group: group,
            initialExpenses: TestData.testSharedExpenses[group.id] ?? [],
            initialBalances: settledBalances,
            initialMembers: members
        )
    }
}
