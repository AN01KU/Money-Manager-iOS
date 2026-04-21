//
//  EditProfileView.swift
//  Money Manager
//

import SwiftUI

struct EditProfileView: View {
    @Environment(\.authService) private var authService
    @Environment(\.dismiss) private var dismiss

    let currentUsername: String
    let currentEmail: String

    @State private var username: String
    @State private var email: String
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showSuccess = false

    init(currentUsername: String, currentEmail: String) {
        self.currentUsername = currentUsername
        self.currentEmail = currentEmail
        _username = State(initialValue: currentUsername)
        _email = State(initialValue: currentEmail)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    LabeledContent("Username") {
                        TextField("Username", text: $username)
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    LabeledContent("Email") {
                        TextField("Email", text: $email)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }

                Section {
                    SecureField("Current Password", text: $currentPassword)
                        .textContentType(.password)
                    SecureField("New Password", text: $newPassword)
                        .textContentType(.newPassword)
                    SecureField("Confirm New Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                } header: {
                    Text("Change Password")
                } footer: {
                    Text("Leave blank to keep your current password.")
                        .font(.caption)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!hasChanges || !isValid || isLoading)
                        .fontWeight(.semibold)
                }
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.ultraThinMaterial)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage ?? "")
            }
            .alert("Profile Updated", isPresented: $showSuccess) {
                Button("Done") { dismiss() }
            } message: {
                Text("Your profile has been updated successfully.")
            }
        }
    }

    private var hasChanges: Bool {
        username != currentUsername ||
        email != currentEmail ||
        !newPassword.isEmpty
    }

    private var isValid: Bool {
        let usernameOK = !username.trimmingCharacters(in: .whitespaces).isEmpty
        let emailOK = email.isValidEmail
        let passwordOK = newPassword.isEmpty || (newPassword == confirmPassword && !currentPassword.isEmpty)
        return usernameOK && emailOK && passwordOK
    }

    private func save() {
        isLoading = true
        errorMessage = nil

        let newUsername = username != currentUsername ? username : nil
        let newEmail = email != currentEmail ? email : nil
        let passwordToSend = newPassword.isEmpty ? nil : newPassword

        Task {
            do {
                try await authService.updateProfile(
                    username: newUsername,
                    email: newEmail,
                    password: passwordToSend
                )
                showSuccess = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
}

#Preview {
    EditProfileView(currentUsername: "Ankush", currentEmail: "ankush@example.com")
}
