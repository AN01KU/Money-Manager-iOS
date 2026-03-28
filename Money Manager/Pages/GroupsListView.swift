//
//  GroupsListView.swift
//  Money Manager
//

import SwiftUI

struct GroupsListView: View {
    @State private var viewModel = GroupsListViewModel()
    @State private var showCreateGroup = false
    @State private var navigationPath: [APIGroupWithDetails] = []
    var pendingRoute: Binding<AppRoute?>?

    var body: some View {
        NavigationStack(path: $navigationPath) {
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
                handlePendingRoute()
            }
            .refreshable {
                await viewModel.load()
            }
            .onChange(of: pendingRoute?.wrappedValue) { _, route in
                guard case .group = route else { return }
                handlePendingRoute()
            }
        }
    }

    private func handlePendingRoute() {
        guard let route = pendingRoute?.wrappedValue,
              case .group(let id) = route,
              let group = viewModel.groups.first(where: { $0.id == id }) else { return }
        navigationPath = [group]
        pendingRoute?.wrappedValue = nil
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
                message: "Create a group to start splitting transactions with others.",
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
                    Text("Recent group transactions will appear here")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.filteredActivity, id: \.transaction.id) { item in
                        ActivityRow(transaction: item.transaction, groupName: item.groupName)

                        if item.transaction.id != viewModel.filteredActivity.last?.transaction.id {
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
