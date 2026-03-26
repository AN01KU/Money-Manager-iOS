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
                CreateGroupSheet(groupService: viewModel.groupService) { newGroup in
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

#Preview("Groups List") {
    GroupsListView()
}
