//
//  GroupsListView.swift
//  Money Manager
//

import SwiftUI

struct GroupsListView: View {
    @State private var viewModel = GroupsListViewModel()
    @State private var showCreateGroup = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                content
                    .background(Color(.systemGroupedBackground))

                if !viewModel.groups.isEmpty {
                    FloatingActionButton(icon: "plus") {
                        showCreateGroup = true
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Groups")
            .searchable(
                text: $viewModel.searchText,
                prompt: viewModel.selectedTab == .groups ? "Search groups" : "Search activity"
            )
            .navigationDestination(for: APIGroupWithDetails.self) { group in
                GroupDetailView(group: group)
            }
            .sheet(isPresented: $showCreateGroup) {
                CreateGroupSheet { newGroup in
                    viewModel.groups.insert(newGroup, at: 0)
                }
            }
            .task {
                await viewModel.load()
            }
            .refreshable {
                await viewModel.load()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.groups.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.groups.isEmpty {
            EmptyStateView(
                icon: "person.3.fill",
                title: "No Groups Yet",
                message: "Create a group to start splitting expenses with others.",
                actionTitle: "Create Group"
            ) {
                showCreateGroup = true
            }
        } else {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("View", selection: $viewModel.selectedTab) {
                        Text("Groups").tag(GroupsTab.groups)
                        Text("Activity").tag(GroupsTab.activities)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if viewModel.selectedTab == .groups {
                        groupsContent
                    } else {
                        activitiesContent
                    }
                }
                .padding(.vertical)
            }
        }
    }

    private var groupsContent: some View {
        VStack(spacing: 16) {
            NetBalanceCard(netBalance: viewModel.netBalance, groupCount: viewModel.groups.count)
                .padding(.horizontal)

            if viewModel.filteredGroups.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundStyle(AppColors.accent)
                    Text("No groups found")
                        .font(.headline)
                    Text("Try a different search term")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.filteredGroups) { group in
                        NavigationLink(value: group) {
                            GroupRow(
                                group: group,
                                memberCount: group.members.count,
                                userBalance: viewModel.userBalance(for: group)
                            )
                        }
                        .buttonStyle(.plain)

                        if group.id != viewModel.filteredGroups.last?.id {
                            Divider()
                                .padding(.leading, 72)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 12))
                .padding(.horizontal)
            }
        }
    }

    private var activitiesContent: some View {
        Group {
            if viewModel.filteredActivity.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.badge.checkmark")
                        .font(.system(size: 40))
                        .foregroundStyle(AppColors.accent)
                    Text("No Recent Activity")
                        .font(.headline)
                    Text("Recent group expenses will appear here")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.filteredActivity, id: \.expense.id) { item in
                        ActivityRow(expense: item.expense, groupName: item.groupName)

                        if item.expense.id != viewModel.filteredActivity.last?.expense.id {
                            Divider()
                                .padding(.leading, 72)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 12))
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Net Balance Card

struct NetBalanceCard: View {
    let netBalance: Double
    let groupCount: Int

    private var isOwed: Bool { netBalance < 0 }
    private var isSettled: Bool { netBalance == 0 }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Net Balance")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(CurrencyFormatter.format(abs(netBalance), showDecimals: true))
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(isSettled ? .primary : (isOwed ? AppColors.positive : AppColors.expense))
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(isSettled ? AppColors.graySubtle : (isOwed ? AppColors.positive.opacity(0.12) : AppColors.expense.opacity(0.12)))
                        .frame(width: 48, height: 48)
                    Image(systemName: isSettled ? "checkmark" : (isOwed ? "arrow.down.left" : "arrow.up.right"))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(isSettled ? .secondary : (isOwed ? AppColors.positive : AppColors.expense))
                }
            }
            HStack {
                Text(isSettled ? "All settled up" : (isOwed ? "You are owed overall" : "You owe overall"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(groupCount) group\(groupCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }
}

// MARK: - Group Row

struct GroupRow: View {
    let group: APIGroupWithDetails
    let memberCount: Int
    let userBalance: Double

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.accentSubtle)
                    .frame(width: 48, height: 48)
                Text(String(group.name.prefix(1)).uppercased())
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                Label("\(memberCount) member\(memberCount == 1 ? "" : "s")", systemImage: "person.2")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if userBalance != 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(CurrencyFormatter.format(abs(userBalance), showDecimals: true))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(userBalance < 0 ? AppColors.positive : AppColors.expense)
                    Text(userBalance < 0 ? "owed" : "owe")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("settled")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .clipShape(.rect(cornerRadius: 8))
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
    }
}

// MARK: - Activity Row

struct ActivityRow: View {
    let expense: APIGroupExpense
    let groupName: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.accentSubtle)
                    .frame(width: 48, height: 48)
                Image(systemName: "dollarsign.circle.fill")
                    .font(.title2)
                    .foregroundStyle(AppColors.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(expense.description)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                Text(groupName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(CurrencyFormatter.format(Double(expense.total_amount) ?? 0, showDecimals: true))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.expense)
                Text(expense.created_at, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
    }
}

// MARK: - Create Group Sheet

struct CreateGroupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var groupName = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    var onCreate: (APIGroupWithDetails) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Group Name")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        TextField("e.g., Weekend Trip", text: $groupName)
                            .textInputAutocapitalization(.words)
                    }
                    .padding(.vertical, 8)
                } footer: {
                    Text("Create a group to start tracking shared expenses with friends.")
                }
            }
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Create") { createGroup() }
                            .fontWeight(.semibold)
                            .disabled(groupName.trimmingCharacters(in: .whitespaces).isEmpty)
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

    private func createGroup() {
        let trimmed = groupName.trimmingCharacters(in: .whitespaces)
        isLoading = true
        Task {
            do {
                let created = try await GroupService.shared.createGroup(name: trimmed)
                let newGroup = APIGroupWithDetails(
                    id: created.id,
                    name: created.name,
                    created_by: created.created_by,
                    created_at: created.created_at,
                    members: [],
                    balances: []
                )
                onCreate(newGroup)
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

#Preview("Groups List") {
    GroupsListView()
}
