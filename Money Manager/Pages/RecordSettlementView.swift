//
//  RecordSettlementView.swift
//  Money Manager
//

import SwiftUI

struct RecordSettlementView: View {
    @Environment(\.dismiss) private var dismiss

    let group: APIGroupWithDetails
    let members: [APIGroupMember]
    let balances: [APIGroupBalance]
    let groupService: GroupServiceProtocol
    var onSettle: (APISettlement) -> Void

    @State private var fromUserId: UUID?
    @State private var toUserId: UUID?
    @State private var amount = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    private var membersWhoOwe: [APIGroupMember] {
        let ids = balances.filter { (Double($0.amount) ?? 0) > 0 }.map(\.user_id)
        return members.filter { ids.contains($0.id) }
    }

    private var membersWhoAreOwed: [APIGroupMember] {
        let ids = balances.filter { (Double($0.amount) ?? 0) < 0 }.map(\.user_id)
        return members.filter { ids.contains($0.id) }
    }

    private var suggestedAmount: Double? {
        guard let fromId = fromUserId, let toId = toUserId else { return nil }
        let fromBal = abs(Double(balances.first(where: { $0.user_id == fromId })?.amount ?? "0") ?? 0)
        let toBal   = abs(Double(balances.first(where: { $0.user_id == toId })?.amount ?? "0") ?? 0)
        let suggested = min(fromBal, toBal)
        return suggested > 0 ? suggested : nil
    }

    private var isFormValid: Bool {
        guard let from = fromUserId, let to = toUserId,
              from != to,
              let amt = Double(amount), amt > 0 else { return false }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Who is paying?") {
                    if membersWhoOwe.isEmpty {
                        Text("No one owes anything").foregroundStyle(.secondary)
                    } else {
                        ForEach(membersWhoOwe) { member in
                            Button {
                                fromUserId = member.id
                                applySuggested()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(displayName(for: member)).foregroundStyle(.primary)
                                        let owes = Double(balances.first(where: { $0.user_id == member.id })?.amount ?? "0") ?? 0
                                        Text("owes \(CurrencyFormatter.format(owes, showDecimals: true))")
                                            .font(.caption).foregroundStyle(AppColors.expense)
                                    }
                                    Spacer()
                                    Image(systemName: fromUserId == member.id ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(fromUserId == member.id ? AppColors.accent : .secondary)
                                }
                            }
                        }
                    }
                }

                Section("Paying to?") {
                    if membersWhoAreOwed.isEmpty {
                        Text("No one is owed anything").foregroundStyle(.secondary)
                    } else {
                        ForEach(membersWhoAreOwed) { member in
                            Button {
                                toUserId = member.id
                                applySuggested()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(displayName(for: member)).foregroundStyle(.primary)
                                        let owed = abs(Double(balances.first(where: { $0.user_id == member.id })?.amount ?? "0") ?? 0)
                                        Text("is owed \(CurrencyFormatter.format(owed, showDecimals: true))")
                                            .font(.caption).foregroundStyle(AppColors.positive)
                                    }
                                    Spacer()
                                    Image(systemName: toUserId == member.id ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(toUserId == member.id ? AppColors.accent : .secondary)
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
                        if let suggested = suggestedAmount {
                            Button {
                                amount = String(format: "%.2f", suggested)
                            } label: {
                                Text("Suggested: \(CurrencyFormatter.format(suggested, showDecimals: true))")
                                    .font(.caption)
                                    .foregroundStyle(AppColors.accent)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Record Settlement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Settle") { recordSettlement() }
                            .fontWeight(.semibold)
                            .disabled(!isFormValid || isLoading)
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

    private func displayName(for member: APIGroupMember) -> String {
        member.email.components(separatedBy: "@").first?.capitalized ?? member.email
    }

    private func applySuggested() {
        if let suggested = suggestedAmount {
            amount = String(format: "%.2f", suggested)
        }
    }

    private func recordSettlement() {
        guard let from = fromUserId, let to = toUserId,
              let amt = Double(amount) else { return }
        isLoading = true
        Task {
            do {
                let request = APICreateSettlementRequest(
                    groupId: group.id,
                    fromUser: from,
                    toUser: to,
                    amount: String(format: "%.2f", amt)
                )
                let settlement = try await groupService.createSettlement(request)
                onSettle(settlement)
                dismiss()
            } catch {
                errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
}
