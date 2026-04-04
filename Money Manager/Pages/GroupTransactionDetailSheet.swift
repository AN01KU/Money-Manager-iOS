import SwiftUI

struct GroupTransactionDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    let transaction: APIGroupTransaction
    let members: [APIGroupMember]
    let currentUserId: UUID?
    let onDelete: (() -> Void)?
    let onEdit: (() -> Void)?

    @State private var showDeleteAlert = false
    @State private var deleteTapped = 0
    @State private var editTapped = 0

    private var amount: Double { Double(transaction.totalAmount) ?? 0 }

    private var paidByName: String {
        members.first(where: { $0.id == transaction.paidByUserId })?.username ?? "Unknown"
    }

    private var isOwner: Bool {
        transaction.paidByUserId == currentUserId
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Amount hero
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(AppColors.accent.opacity(0.15))
                                .frame(width: 80, height: 80)
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(AppColors.accent)
                        }

                        Text(transaction.description ?? transaction.category)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)

                        Text(CurrencyFormatter.format(amount, showDecimals: true))
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(AppColors.expense)

                        Text(transaction.date, style: .date)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)

                    // Details card
                    VStack(alignment: .leading, spacing: 16) {
                        DetailRow(label: "Category", value: transaction.category)
                        DetailRow(label: "Paid By", value: paidByName)
                        DetailRow(label: "Split Among", value: "\(transaction.splits.count) member\(transaction.splits.count == 1 ? "" : "s")")
                        DetailRow(label: "Date", value: transaction.date.formatted(date: .long, time: .omitted))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(.rect(cornerRadius: 16))

                    // Splits breakdown
                    if !transaction.splits.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Split Breakdown")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            ForEach(transaction.splits, id: \.userId) { split in
                                let name = members.first(where: { $0.id == split.userId })?.username ?? "Unknown"
                                HStack {
                                    Text(name)
                                    Spacer()
                                    Text(CurrencyFormatter.format(Double(split.amount) ?? 0, showDecimals: true))
                                        .fontWeight(.medium)
                                }
                                .font(.subheadline)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(.rect(cornerRadius: 16))
                    }

                    if isOwner {
                        HStack(spacing: 16) {
                            if let onEdit {
                                Button {
                                    editTapped += 1
                                    onEdit()
                                    dismiss()
                                } label: {
                                    Text("Edit")
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(AppColors.accent)
                                        .foregroundStyle(.white)
                                        .clipShape(.rect(cornerRadius: 12))
                                }
                                .sensoryFeedback(.impact(weight: .light), trigger: editTapped)
                            }

                            if let onDelete {
                                Button {
                                    deleteTapped += 1
                                    showDeleteAlert = true
                                } label: {
                                    Text("Delete")
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(AppColors.expense)
                                        .foregroundStyle(.white)
                                        .clipShape(.rect(cornerRadius: 12))
                                }
                                .sensoryFeedback(.warning, trigger: deleteTapped)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
            }
            .navigationTitle("Transaction Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Delete Transaction?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    onDelete?()
                    dismiss()
                }
            } message: {
                Text("This will remove the transaction from the group. This cannot be undone.")
            }
        }
    }
}
