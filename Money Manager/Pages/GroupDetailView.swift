//
//  GroupDetailView.swift
//  Money Manager
//

import SwiftUI

struct GroupDetailView: View {
    @State private var viewModel: GroupDetailViewModel
    @State private var selectedTransaction: APIGroupTransaction?
    @State private var transactionToEdit: APIGroupTransaction?

    init(group: APIGroupWithDetails, currentUserId: UUID?) {
        _viewModel = State(wrappedValue: GroupDetailViewModel(group: group, currentUserId: currentUserId))
    }

    var body: some View {
        VStack(spacing: 0) {
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
        .sheet(isPresented: $viewModel.showAddTransaction) {
            AddTransactionView(
                mode: .shared(
                    group: viewModel.group,
                    members: viewModel.members,
                    currentUserId: viewModel.currentUserId
                ) { newExpense in
                    viewModel.transactionAdded(newExpense)
                },
                groupService: viewModel.groupService
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
        .sheet(item: $selectedTransaction) { transaction in
            GroupTransactionDetailSheet(
                transaction: transaction,
                members: viewModel.members,
                currentUserId: viewModel.currentUserId,
                onDelete: viewModel.currentUserId == transaction.paidByUserId ? {
                    viewModel.deleteTransaction(transaction)
                } : nil,
                onEdit: viewModel.currentUserId == transaction.paidByUserId ? {
                    transactionToEdit = transaction
                } : nil
            )
        }
        .sheet(item: $transactionToEdit) { transaction in
            AddTransactionView(
                mode: .shared(
                    group: viewModel.group,
                    members: viewModel.members,
                    currentUserId: viewModel.currentUserId,
                    editing: transaction
                ) { updated in
                    viewModel.transactionEdited(replacing: transaction, with: updated)
                },
                groupService: viewModel.groupService
            )
        }
        .task {
            await viewModel.loadData()
        }
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch viewModel.selectedSection {
        case .transactions: transactionsSection
        case .balances:     balancesSection
        case .members:      membersSection
        }
    }

    @ViewBuilder
    private var fabView: some View {
        switch viewModel.selectedSection {
        case .transactions:
            FloatingActionButton(icon: "plus") { viewModel.showAddTransaction = true }
        case .balances:
            if viewModel.hasUnsettledBalances {
                FloatingActionButton(icon: "arrow.left.arrow.right") { viewModel.showSettlement = true }
            }
        case .members:
            FloatingActionButton(icon: "person.badge.plus") { viewModel.showAddMember = true }
        }
    }

    private var transactionsSection: some View {
        Group {
            if viewModel.transactions.isEmpty {
                EmptyStateView(icon: "receipt", title: "No Transactions", message: "Add the first transaction to this group.")
                    .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(groupedTransactions) { section in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(section.label)
                                    .font(AppTypography.sectionHeader)
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 4)

                                VStack(spacing: 0) {
                                    ForEach(Array(section.transactions.enumerated()), id: \.element.id) { index, transaction in
                                        Button {
                                            selectedTransaction = transaction
                                        } label: {
                                            GroupTransactionRow(transaction: transaction, members: viewModel.members, currentUserId: viewModel.currentUserId)
                                        }
                                        .buttonStyle(.plain)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            if transaction.paidByUserId == viewModel.currentUserId {
                                                Button(role: .destructive) {
                                                    viewModel.deleteTransaction(transaction)
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                        }

                                        if index < section.transactions.count - 1 {
                                            Divider().padding(.leading, 58)
                                        }
                                    }
                                }
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .padding(.bottom, 80)
                }
            }
        }
    }

    private struct GroupTransactionSection: Identifiable {
        let id: String
        let label: String
        let transactions: [APIGroupTransaction]
    }

    private var groupedTransactions: [GroupTransactionSection] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd"
        var grouped: [String: [APIGroupTransaction]] = [:]

        for tx in viewModel.transactions {
            let day = calendar.startOfDay(for: tx.date)
            let key = calendar.isDateInToday(day)
                ? "TODAY"
                : formatter.string(from: day).uppercased()
            grouped[key, default: []].append(tx)
        }

        return grouped
            .map { GroupTransactionSection(id: $0.key, label: $0.key, transactions: $0.value) }
            .sorted { a, b in
                if a.id == "TODAY" { return true }
                if b.id == "TODAY" { return false }
                return a.id > b.id
            }
    }

    private var balancesSection: some View {
        Group {
            if viewModel.balances.isEmpty {
                EmptyStateView(icon: "scale.3d", title: "No Balances", message: "Balances will appear once transactions are added.")
                    .frame(maxHeight: .infinity)
            } else {
                let debts = viewModel.pairwiseDebts
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Outstanding balances
                        VStack(alignment: .leading, spacing: 6) {
                            Text("OUTSTANDING")
                                .font(AppTypography.sectionHeader)
                                .foregroundStyle(.secondary)
                                .padding(.leading, 4)

                            VStack(spacing: 0) {
                                if debts.isEmpty {
                                    GroupBalanceSettledRow()
                                } else {
                                    ForEach(Array(debts.enumerated()), id: \.element.id) { index, debt in
                                        GroupBalanceRow(
                                            debt: debt,
                                            members: viewModel.members,
                                            currentUserId: viewModel.currentUserId
                                        )
                                        if index < debts.count - 1 {
                                            Divider().padding(.leading, 58)
                                        }
                                    }
                                }
                            }
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // Settlement history
                        if !viewModel.settlements.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("SETTLEMENT HISTORY")
                                    .font(AppTypography.sectionHeader)
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 4)

                                VStack(spacing: 0) {
                                    ForEach(Array(viewModel.settlements.enumerated()), id: \.element.id) { index, settlement in
                                        SettlementHistoryRow(
                                            settlement: settlement,
                                            members: viewModel.members,
                                            currentUserId: viewModel.currentUserId
                                        )
                                        if index < viewModel.settlements.count - 1 {
                                            Divider().padding(.leading, 58)
                                        }
                                    }
                                }
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .padding(.bottom, 80)
                }
            }
        }
    }

    private var membersSection: some View {
        Group {
            if viewModel.members.isEmpty {
                EmptyStateView(icon: "person.3", title: "No Members", message: "Invite people to join this group.")
                    .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.members.enumerated()), id: \.element.id) { index, member in
                            GroupMemberRow(
                                member: member,
                                isAdmin: member.id == viewModel.group.createdBy,
                                isPending: viewModel.isPending(member)
                            )
                            if index < viewModel.members.count - 1 {
                                Divider().padding(.leading, 58)
                            }
                        }
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .padding(.bottom, 80)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Group Detail") {
    let group = APIGroupWithDetails(
        id: UUID(),
        name: "Weekend Trip",
        createdBy: UUID(),
        createdAt: Date(),
        members: [],
        balances: []
    )
    NavigationStack {
        GroupDetailView(group: group, currentUserId: nil)
    }
}
