//
//  TransactionDetailView.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 13/01/26.
//

import SwiftUI
import SwiftData

struct TransactionDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let expense: Expense
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var selectedGroup: SplitGroup?
    
    var category: PredefinedCategory? {
        PredefinedCategory.allCases.first { $0.rawValue == expense.category }
    }
    
    var isGroupExpense: Bool {
        expense.groupId != nil && expense.groupName != nil
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Group Badge (if applicable)
                    if isGroupExpense {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(.teal)
                                Text("Group Expense")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.teal)
                                Spacer()
                            }
                            
                            NavigationLink(value: getGroupForNavigation()) { 
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(expense.groupName ?? "Unknown Group")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                        
                                        Text("Tap to view group details")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color.teal.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                    }
                    
                    // Header
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill((category?.color ?? Color.gray).opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: category?.icon ?? "ellipsis.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(category?.color ?? Color.gray)
                        }
                        
                        Text(expense.category)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("₹\(formatAmount(expense.amount))")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.red)
                        
                        Text(formatDateAndTime(expense.date, time: expense.time))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Details Section
                    VStack(alignment: .leading, spacing: 16) {
                        if let description = expense.expenseDescription, !description.isEmpty {
                            DetailRow(label: "Description", value: description)
                        }
                        
                        if let notes = expense.notes, !notes.isEmpty {
                            DetailRow(label: "Notes", value: notes)
                        }
                        
                        DetailRow(label: "Category", value: expense.category)
                        
                        DetailRow(label: "Created", value: formatFullDate(expense.createdAt))
                        
                        if expense.updatedAt != expense.createdAt {
                            DetailRow(label: "Last Modified", value: formatFullDate(expense.updatedAt))
                        }
                        
                        if expense.isRecurring {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.teal)
                                Text("This is a recurring expense")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.teal.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    // Actions
                    HStack(spacing: 16) {
                        Button(action: {
                            showEditSheet = true
                        }) {
                            Text("Edit")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.teal)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            showDeleteAlert = true
                        }) {
                            Text("Delete")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("Transaction Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: SplitGroup.self) { group in
                GroupDetailView(group: group)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                AddExpenseView(expenseToEdit: expense)
            }
            .alert("Delete Expense?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteExpense()
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
    
    private func deleteExpense() {
        expense.isDeleted = true
        expense.updatedAt = Date()
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error deleting expense: \(error)")
        }
    }
    
    private func getGroupForNavigation() -> SplitGroup? {
        guard let groupId = expense.groupId, let groupName = expense.groupName else { return nil }
        return SplitGroup(
            id: groupId,
            name: groupName,
            createdBy: UUID(),
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
    
    private func formatDateAndTime(_ date: Date, time: Date?) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        if let time = time {
            dateFormatter.timeStyle = .short
            return dateFormatter.string(from: date)
        } else {
            dateFormatter.timeStyle = .none
            return dateFormatter.string(from: date)
        }
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    TransactionDetailView(expense: Expense(
        amount: 450,
        category: "Food & Dining",
        date: Date(),
        time: Date(),
        expenseDescription: "Lunch at cafe"
    ))
}
