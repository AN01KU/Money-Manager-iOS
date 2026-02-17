import SwiftUI

struct RecordSettlementView: View {
    @Environment(\.dismiss) var dismiss
    
    let group: SplitGroup
    let members: [APIUser]
    let balances: [UserBalance]
    var onSettle: (Settlement) -> Void
    
    @State private var fromUserId: UUID?
    @State private var toUserId: UUID?
    @State private var amount = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private var membersWhoOwe: [APIUser] {
        let owingIds = balances.filter { (Double($0.amount) ?? 0) > 0 }.map(\.userId)
        return members.filter { owingIds.contains($0.id) }
    }
    
    private var membersWhoAreOwed: [APIUser] {
        let owedIds = balances.filter { (Double($0.amount) ?? 0) < 0 }.map(\.userId)
        return members.filter { owedIds.contains($0.id) }
    }
    
    private var suggestedAmount: Double? {
        guard let fromId = fromUserId, let toId = toUserId else { return nil }
        let fromBalance = Double(balances.first(where: { $0.userId == fromId })?.amount ?? "0") ?? 0
        let toBalance = abs(Double(balances.first(where: { $0.userId == toId })?.amount ?? "0") ?? 0)
        return min(fromBalance, toBalance)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Who is paying?") {
                    if membersWhoOwe.isEmpty {
                        Text("No one owes anything")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(membersWhoOwe) { member in
                            Button {
                                fromUserId = member.id
                                updateSuggestedAmount()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(MockData.nameForUser(member.id))
                                            .foregroundColor(.primary)
                                        
                                        let owes = Double(balances.first(where: { $0.userId == member.id })?.amount ?? "0") ?? 0
                                        Text("owes \(CurrencyFormatter.format(owes, showDecimals: true))")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                    
                                    Spacer()
                                    
                                    if fromUserId == member.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.teal)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section("Paying to?") {
                    if membersWhoAreOwed.isEmpty {
                        Text("No one is owed anything")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(membersWhoAreOwed) { member in
                            Button {
                                toUserId = member.id
                                updateSuggestedAmount()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(MockData.nameForUser(member.id))
                                            .foregroundColor(.primary)
                                        
                                        let owed = abs(Double(balances.first(where: { $0.userId == member.id })?.amount ?? "0") ?? 0)
                                        Text("is owed \(CurrencyFormatter.format(owed, showDecimals: true))")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    }
                                    
                                    Spacer()
                                    
                                    if toUserId == member.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.teal)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.secondary)
                                    }
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
                        
                        if let suggested = suggestedAmount, suggested > 0 {
                            Button {
                                amount = String(format: "%.2f", suggested)
                            } label: {
                                Text("Suggested: \(CurrencyFormatter.format(suggested, showDecimals: true))")
                                    .font(.caption)
                                    .foregroundColor(.teal)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                if let fromId = fromUserId, let toId = toUserId, let amt = Double(amount), amt > 0 {
                    Section("Summary") {
                        HStack {
                            VStack {
                                Text(MockData.nameForUser(fromId))
                                    .font(.headline)
                                Text("pays")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "arrow.right")
                                .font(.title3)
                                .foregroundColor(.teal)
                            
                            Spacer()
                            
                            VStack {
                                Text(MockData.nameForUser(toId))
                                    .font(.headline)
                                Text("receives")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                        
                        HStack {
                            Spacer()
                            Text(CurrencyFormatter.format(amt, showDecimals: true))
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.teal)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Record Settlement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settle") { recordSettlement() }
                        .fontWeight(.semibold)
                        .disabled(!isFormValid || isLoading)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        guard let fromId = fromUserId,
              let toId = toUserId,
              fromId != toId,
              let amt = Double(amount), amt > 0 else {
            return false
        }
        return true
    }
    
    private func updateSuggestedAmount() {
        if let suggested = suggestedAmount, suggested > 0 {
            amount = String(format: "%.2f", suggested)
        }
    }
    
    private func recordSettlement() {
        guard let fromId = fromUserId, let toId = toUserId else { return }
        
        isLoading = true
        Task {
            if MockData.useDummyData {
                try? await Task.sleep(for: .milliseconds(300))
                let settlement = Settlement(
                    id: UUID(),
                    groupId: group.id,
                    fromUser: fromId,
                    toUser: toId,
                    amount: String(format: "%.2f", Double(amount) ?? 0),
                    createdAt: ISO8601DateFormatter().string(from: Date())
                )
                onSettle(settlement)
            } else {
                do {
                    let request = CreateSettlementRequest(
                        groupId: group.id,
                        fromUser: fromId,
                        toUser: toId,
                        amount: String(format: "%.2f", Double(amount) ?? 0)
                    )
                    let settlement = try await APIService.shared.createSettlement(request)
                    onSettle(settlement)
                } catch {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                    return
                }
            }
            isLoading = false
            dismiss()
        }
    }
}

#Preview {
    RecordSettlementView(
        group: MockData.groups[0],
        members: MockData.groupMembers[MockData.groups[0].id]!,
        balances: MockData.balances[MockData.groups[0].id]!
    ) { _ in }
}
