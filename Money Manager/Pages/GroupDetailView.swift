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
                balances: viewModel.balances,
                groupService: viewModel.groupService
            ) { settlement in
                viewModel.settlementRecorded(settlement)
            }
        }
        .sheet(isPresented: $viewModel.showAddMember) {
            AddMemberSheet(existingMembers: viewModel.members) { email in
                viewModel.addMember(email: email)
            }
        }
        .alert("Error", isPresented: $viewModel.showAddMemberError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.addMemberError ?? "")
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
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
