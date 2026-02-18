import SwiftUI

struct GroupsListView: View {
    var groups: [SplitGroup]?
    var balances: [UUID: [UserBalance]] = [:]
    var expenses: [UUID: [SharedExpense]] = [:]
    var members: [UUID: [APIUser]] = [:]
    
    @StateObject private var viewModel: GroupsListViewModel
    
    init(groups: [SplitGroup]? = nil,
         balances: [UUID: [UserBalance]] = [:],
         expenses: [UUID: [SharedExpense]] = [:],
         members: [UUID: [APIUser]] = [:]) {
        _viewModel = StateObject(wrappedValue: GroupsListViewModel(
            groups: groups,
            balances: balances,
            expenses: expenses,
            members: members
        ))
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.groups.isEmpty {
                        EmptyStateView(
                            icon: "person.3.fill",
                            actionTitle: "Create Group"
                        ) {
                            viewModel.showCreateGroup = true
                        }
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                Picker("View", selection: $viewModel.selectedTab) {
                                    Text("Groups").tag(ViewTab.groups)
                                    Text("Activities").tag(ViewTab.activities)
                                }
                                .pickerStyle(.segmented)
                                .padding()
                                
                                if viewModel.selectedTab == .groups {
                                    groupsContent
                                } else {
                                    activitiesContent
                                }
                            }
                            .padding(.vertical)
                        }
                        .background(Color(.systemGroupedBackground))
                    }
                }
                
                if !viewModel.groups.isEmpty {
                    FloatingActionButton(icon: "plus") {
                        viewModel.showCreateGroup = true
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Groups")
            .searchable(text: $viewModel.searchText, prompt: viewModel.selectedTab == .groups ? "Search groups" : "Search activities")
            .navigationDestination(for: SplitGroup.self) { group in
                GroupDetailView(group: group)
            }
            .sheet(isPresented: $viewModel.showCreateGroup) {
                CreateGroupSheet { newGroup in
                    viewModel.addGroup(newGroup)
                }
            }
            .task {
                await viewModel.loadGroups()
            }
        }
    }
    
    private var netBalanceCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Net Balance")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(CurrencyFormatter.format(abs(viewModel.netBalance), showDecimals: true))
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(viewModel.netBalance == 0 ? .primary : (viewModel.netBalance < 0 ? .green : .red))
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(viewModel.netBalance == 0 ? Color.gray.opacity(0.12) : (viewModel.netBalance < 0 ? Color.green.opacity(0.12) : Color.red.opacity(0.12)))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: viewModel.netBalance == 0 ? "checkmark" : (viewModel.netBalance < 0 ? "arrow.down.left" : "arrow.up.right"))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(viewModel.netBalance == 0 ? .gray : (viewModel.netBalance < 0 ? .green : .red))
                }
            }
            
            HStack {
                Text(viewModel.netBalance == 0 ? "All settled up" : (viewModel.netBalance < 0 ? "You are owed overall" : "You owe overall"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(viewModel.groups.count) group\(viewModel.groups.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private var groupsContent: some View {
        VStack(spacing: 16) {
            netBalanceCard
                .padding(.horizontal)
            
            if viewModel.filteredGroups.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundColor(.teal)
                        .padding(.bottom, 8)
                    
                    Text("No groups found")
                        .font(.headline)
                    
                    Text("Try a different search term")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.filteredGroups) { group in
                        NavigationLink(value: group) {
                            GroupRow(
                                group: group,
                                memberCount: viewModel.groupMembers[group.id]?.count ?? 0,
                                userBalance: viewModel.userBalance(for: group.id)
                            )
                        }
                        .buttonStyle(.plain)
                        
                        if group.id != viewModel.filteredGroups.last?.id {
                            Divider()
                                .padding(.leading, 72)
                        }
                    }
                }
                .padding(.horizontal)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
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
                        .foregroundColor(.teal)
                        .padding(.bottom, 8)
                    
                    Text(viewModel.searchText.isEmpty ? "No Activities Yet" : "No activities found")
                        .font(.headline)
                    
                    Text(viewModel.searchText.isEmpty ? "Recent activities will appear here" : "Try a different search term")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding()
            } else {
                recentActivitySection
                    .padding(.horizontal)
            }
        }
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Activity")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                ForEach(Array(viewModel.filteredActivity.enumerated()), id: \.element.expense.id) { index, item in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.groupName)
                                .font(.caption)
                                .foregroundColor(.teal)
                            
                            Text(item.expense.description)
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(CurrencyFormatter.format(Double(item.expense.totalAmount) ?? 0))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text(viewModel.nameForUser(item.expense.paidBy) + " paid")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(viewModel.relativeTime(from: item.expense.createdAt))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal)
                    
                    if index < viewModel.filteredActivity.count - 1 {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
}

struct GroupRow: View {
    let group: SplitGroup
    var memberCount: Int = 0
    var userBalance: Double = 0
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.teal.opacity(0.12))
                    .frame(width: 48, height: 48)
                
                Text(String(group.name.prefix(1)).uppercased())
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.teal)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                Label("\(memberCount) member\(memberCount == 1 ? "" : "s")", systemImage: "person.2")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if userBalance != 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(CurrencyFormatter.format(abs(userBalance)))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(userBalance < 0 ? .green : .red)
                    
                    Text(userBalance < 0 ? "owed" : "owe")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("settled")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
    }
}

struct CreateGroupSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var groupName = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var onCreate: (SplitGroup) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Group Name")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Create") {
                            createGroup()
                        }
                        .fontWeight(.semibold)
                        .disabled(groupName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func createGroup() {
        isLoading = true
        let trimmedName = groupName.trimmingCharacters(in: .whitespaces)
        
        Task {
            do {
                let group: SplitGroup
                
                if useTestData {
                    try? await Task.sleep(for: .milliseconds(300))
                    group = SplitGroup(
                        id: UUID(),
                        name: trimmedName,
                        createdBy: TestData.currentUser.id,
                        createdAt: ISO8601DateFormatter().string(from: Date())
                    )
                } else {
                    group = try await APIService.shared.createGroup(name: trimmedName)
                }
                
                onCreate(group)
                isLoading = false
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                isLoading = false
            }
        }
    }
}

// MARK: - Previews

#Preview("With Groups") {
    GroupsListView(
        groups: TestData.testGroups,
        balances: TestData.testBalances,
        expenses: TestData.testSharedExpenses,
        members: TestData.testGroupMembers
    )
}

#Preview("Empty State") {
    GroupsListView(groups: [])
}

#Preview("Single Group") {
    let group = TestData.testGroups[0]
    GroupsListView(
        groups: [group],
        balances: [group.id: TestData.testBalances[group.id] ?? []],
        expenses: [group.id: TestData.testSharedExpenses[group.id] ?? []],
        members: [group.id: TestData.testGroupMembers[group.id] ?? []]
    )
}
