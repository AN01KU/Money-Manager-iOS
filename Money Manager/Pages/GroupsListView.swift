import SwiftUI

struct GroupsListView: View {
    @State private var groups: [SplitGroup] = []
    @State private var showCreateGroup = false
    @State private var isLoading = false
    @State private var selectedTab: ViewTab = .groups
    @State private var searchText = ""
    
    enum ViewTab {
        case groups
        case activities
    }
    
    private var filteredGroups: [SplitGroup] {
        if searchText.isEmpty {
            return groups
        }
        return groups.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    private var netBalance: Double {
        let currentUserId = MockData.useDummyData ? MockData.currentUser.id : APIService.shared.currentUser?.id
        guard let userId = currentUserId else { return 0 }
        
        var total = 0.0
        for group in groups {
            if let balances = MockData.balances[group.id],
               let userBalance = balances.first(where: { $0.userId == userId }) {
                total += Double(userBalance.amount) ?? 0
            }
        }
        return total
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if groups.isEmpty {
                        EmptyStateView(
                            icon: "person.3.fill",
                            title: "No groups yet",
                            message: "Split expenses with friends, roommates, or on trips",
                            actionTitle: "Create Group"
                        ) {
                            showCreateGroup = true
                        }
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                // Segmented Control
                                Picker("View", selection: $selectedTab) {
                                    Text("Groups").tag(ViewTab.groups)
                                    Text("Activities").tag(ViewTab.activities)
                                }
                                .pickerStyle(.segmented)
                                .padding()
                                
                                if selectedTab == .groups {
                                    groupsContent
                                } else {
                                    activitiesContent
                                }
                            }
                            .padding(.vertical)
                        }
                        .background(Color(.systemGroupedBackground))
                        .onChange(of: selectedTab) { _, newTab in
                            if newTab == .groups {
                                searchText = ""
                            }
                        }
                    }
                }
                
                if !groups.isEmpty {
                    FloatingActionButton(icon: "plus") {
                        showCreateGroup = true
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Groups")
            .searchable(text: $searchText, prompt: "Search groups")
            .navigationDestination(for: SplitGroup.self) { group in
                GroupDetailView(group: group)
            }
            .sheet(isPresented: $showCreateGroup) {
                CreateGroupSheet { newGroup in
                    groups.insert(newGroup, at: 0)
                }
            }
            .task {
                await loadGroups()
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
                    
                    Text(CurrencyFormatter.format(abs(netBalance), showDecimals: true))
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(netBalance == 0 ? .primary : (netBalance < 0 ? .green : .red))
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(netBalance == 0 ? Color.gray.opacity(0.12) : (netBalance < 0 ? Color.green.opacity(0.12) : Color.red.opacity(0.12)))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: netBalance == 0 ? "checkmark" : (netBalance < 0 ? "arrow.down.left" : "arrow.up.right"))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(netBalance == 0 ? .gray : (netBalance < 0 ? .green : .red))
                }
            }
            
            HStack {
                Text(netBalance == 0 ? "All settled up" : (netBalance < 0 ? "You are owed overall" : "You owe overall"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(groups.count) group\(groups.count == 1 ? "" : "s")")
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
            
            if filteredGroups.isEmpty {
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
                    ForEach(filteredGroups) { group in
                        NavigationLink(value: group) {
                            GroupRow(group: group)
                        }
                        .buttonStyle(.plain)
                        
                        if group.id != filteredGroups.last?.id {
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
            if recentActivity.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.badge.checkmark")
                        .font(.system(size: 40))
                        .foregroundColor(.teal)
                        .padding(.bottom, 8)
                    
                    Text("No Activities Yet")
                        .font(.headline)
                    
                    Text("Recent activities will appear here")
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
    
    private var recentActivity: [(expense: SharedExpense, groupName: String)] {
        var all: [(expense: SharedExpense, groupName: String)] = []
        for group in groups {
            if let expenses = MockData.expenses[group.id] {
                for expense in expenses {
                    all.append((expense: expense, groupName: group.name))
                }
            }
        }
        return all
            .sorted { $0.expense.createdAt > $1.expense.createdAt }
            .prefix(5)
            .map { $0 }
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Activity")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                ForEach(Array(recentActivity.enumerated()), id: \.element.expense.id) { index, item in
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
                            
                            Text(MockData.nameForUser(item.expense.paidBy) + " paid")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(relativeTime(from: item.expense.createdAt))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal)
                    
                    if index < recentActivity.count - 1 {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    private func relativeTime(from isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else { return "" }
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval / 60)
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)
        let weeks = Int(interval / 604800)
        
        if minutes < 1 { return "now" }
        if minutes < 60 { return "\(minutes)m ago" }
        if hours < 24 { return "\(hours)h ago" }
        if days < 7 { return "\(days)d ago" }
        return "\(weeks)w ago"
    }
    
    private func loadGroups() async {
        isLoading = true
        if MockData.useDummyData {
            try? await Task.sleep(for: .milliseconds(400))
            groups = MockData.groups
        } else {
            // TODO: Fetch from API when backend is ready
        }
        isLoading = false
    }
}

struct GroupRow: View {
    let group: SplitGroup
    
    private var memberCount: Int {
        MockData.groupMembers[group.id]?.count ?? 0
    }
    
    private var userBalance: Double {
        let userId = MockData.useDummyData ? MockData.currentUser.id : APIService.shared.currentUser?.id
        guard let userId else { return 0 }
        if let balances = MockData.balances[group.id],
           let balance = balances.first(where: { $0.userId == userId }) {
            return Double(balance.amount) ?? 0
        }
        return 0
    }
    
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
                
                if MockData.useDummyData {
                    try? await Task.sleep(for: .milliseconds(300))
                    group = SplitGroup(
                        id: UUID(),
                        name: trimmedName,
                        createdBy: MockData.currentUser.id,
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

#Preview {
    GroupsListView()
}
