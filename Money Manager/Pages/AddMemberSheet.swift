//
//  AddMemberSheet.swift
//  Money Manager
//

import SwiftUI

struct AddMemberSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""

    let existingMembers: [APIGroupMember]
    var onAdd: (String) -> Void

    private var trimmed: String { email.trimmingCharacters(in: .whitespaces) }
    private var isValid: Bool { !trimmed.isEmpty && trimmed.contains("@") }
    private var isAlreadyMember: Bool {
        existingMembers.contains { $0.email.lowercased() == trimmed.lowercased() }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        TextField("e.g., friend@example.com", text: $email)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                    }
                    .padding(.vertical, 8)
                } footer: {
                    if isAlreadyMember {
                        Text("This user is already a member of the group.")
                            .foregroundStyle(AppColors.expense)
                    } else {
                        Text("An invite will be sent. They'll appear as \"Invited\" until they join.")
                    }
                }
            }
            .dismissKeyboardOnScroll()
            .navigationTitle("Invite Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Invite") {
                        onAdd(trimmed)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid || isAlreadyMember)
                }
            }
        }
    }
}
