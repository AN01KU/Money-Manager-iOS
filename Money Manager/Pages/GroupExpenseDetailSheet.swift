import SwiftUI

struct GroupExpenseDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    let expense: APIGroupTransaction
    let members: [APIGroupMember]
    let currentUserId: UUID?
    let onDelete: (() -> Void)?

    @State private var showDeleteAlert = false
    @State private var deleteTapped = false

    private var amount: Double { Double(expense.total_amount) ?? 0 }

    private var paidByName: String {
        members.first(where: { $0.id == expense.paid_by_user_id })?.username ?? "Unknown"
    }

    private var isOwner: Bool {
        expense.paid_by_user_id == currentUserId
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

                        Text(expense.description ?? expense.category)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)

                        Text(CurrencyFormatter.format(amount, showDecimals: true))
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(AppColors.expense)

                        Text(expense.date, style: .date)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)

                    // Details card
                    VStack(alignment: .leading, spacing: 16) {
                        DetailRow(label: "Category", value: expense.category)
                        DetailRow(label: "Paid By", value: paidByName)
                        DetailRow(label: "Split Among", value: "\(expense.splits.count) member\(expense.splits.count == 1 ? "" : "s")")
                        DetailRow(label: "Date", value: expense.date.formatted(date: .long, time: .omitted))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(.rect(cornerRadius: 16))

                    // Splits breakdown
                    if !expense.splits.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Split Breakdown")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            ForEach(expense.splits, id: \.user_id) { split in
                                let name = members.first(where: { $0.id == split.user_id })?.username ?? "Unknown"
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

                    if isOwner, let onDelete {
                        Button {
                            deleteTapped = true
                            showDeleteAlert = true
                        } label: {
                            Text("Delete Expense")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppColors.expense)
                                .foregroundStyle(.white)
                                .clipShape(.rect(cornerRadius: 12))
                        }
                        .sensoryFeedback(.warning, trigger: deleteTapped)
                        .onChange(of: deleteTapped) { _, v in if v { deleteTapped = false } }
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
            .alert("Delete Expense?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    onDelete?()
                    dismiss()
                }
            } message: {
                Text("This will remove the expense from the group. This cannot be undone.")
            }
        }
    }
}
