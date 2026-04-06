//
//  GroupsListView.swift
//  Money Manager
//

import SwiftUI

struct GroupsListView: View {
    @Environment(\.authService) private var authService
    @State private var viewModel = GroupsListViewModel()
    @State private var showCreateGroup = false
    @State private var navigationPath: [APIGroupWithDetails] = []
    var pendingRoute: Binding<AppRoute?>?

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .bottomTrailing) {
                GroupsListContent(viewModel: viewModel, onCreateGroup: { showCreateGroup = true })
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
                GroupDetailView(group: group, currentUserId: authService.currentUser?.id)
            }
            .sheet(isPresented: $showCreateGroup) {
                CreateGroupSheet(groupService: viewModel.groupService) { newGroup in
                    viewModel.groups.insert(newGroup, at: 0)
                }
            }
            .task {
                viewModel.setCurrentUser(authService.currentUser?.id)
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
}

private struct GroupsListContent: View {
    @Bindable var viewModel: GroupsListViewModel
    let onCreateGroup: () -> Void

    @ViewBuilder
    var body: some View {
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
                onCreateGroup()
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
                        GroupsGroupsContent(viewModel: viewModel, onCreateGroup: onCreateGroup)
                    } else {
                        GroupsActivitiesContent(viewModel: viewModel)
                    }
                }
                .padding(.vertical)
            }
        }
    }
}

private struct GroupsGroupsContent: View {
    @Bindable var viewModel: GroupsListViewModel
    let onCreateGroup: () -> Void

    var body: some View {
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
                        .accessibilityIdentifier("groups.group-row")

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
}

private struct GroupsActivitiesContent: View {
    @Bindable var viewModel: GroupsListViewModel

    var body: some View {
        Group {
            if viewModel.filteredActivity.isEmpty {
                EmptyStateView(
                    icon: "clock.badge.checkmark",
                    title: "No Recent Activity",
                    message: "Group transactions and settlements will appear here."
                )
                .padding(.top, 32)
            } else {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(viewModel.groupedActivity) { section in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(section.label)
                                .font(AppTypography.sectionHeader)
                                .foregroundStyle(.secondary)
                                .padding(.leading, 4)
                                .padding(.horizontal)

                            VStack(spacing: 0) {
                                ForEach(Array(section.items.enumerated()), id: \.element.id) { index, item in
                                    ActivityRow(item: item, currentUserId: viewModel.currentUserId)

                                    if index < section.items.count - 1 {
                                        Divider().padding(.leading, 64)
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
        }
    }
}

#Preview("Groups List") {
    GroupsListView()
}
