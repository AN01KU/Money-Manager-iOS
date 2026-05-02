//
//  CreateGroupSheet.swift
//  Money Manager
//

import SwiftUI

struct CreateGroupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var groupName = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    let groupService: GroupServiceProtocol
    var onCreate: (APIGroupWithDetails) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(
                    header: Text("Group Name"),
                    footer: Text("Create a group to start tracking shared transactions with friends.")
                ) {
                    TextField("e.g., Weekend Trip", text: $groupName)
                        .textInputAutocapitalization(.words)
                }
            }
            .dismissKeyboardOnScroll()
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Create") { createGroup() }
                            .fontWeight(.semibold)
                            .disabled(groupName.trimmingCharacters(in: .whitespaces).isEmpty)
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

    private func createGroup() {
        let trimmed = groupName.trimmingCharacters(in: .whitespaces)
        isLoading = true
        Task {
            do {
                let created = try await groupService.createGroup(name: trimmed)
                let newGroup = APIGroupWithDetails(
                    id: created.id,
                    name: created.name,
                    createdBy: created.createdBy,
                    createdAt: created.createdAt,
                    members: [],
                    balances: []
                )
                onCreate(newGroup)
                dismiss()
            } catch {
                errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
}
