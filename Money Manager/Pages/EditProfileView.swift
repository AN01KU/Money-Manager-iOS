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
            ScrollView {
                VStack(spacing: AppConstants.UI.spacing20) {
                    // PROFILE section
                    VStack(alignment: .leading, spacing: AppConstants.UI.spacingSM) {
                        Text("PROFILE")
                            .font(AppTypography.sectionHeader)
                            .foregroundStyle(AppColors.label2)

                        VStack(spacing: 0) {
                            ProfileFieldRow(label: "Username") {
                                TextField("Username", text: $username)
                                    .multilineTextAlignment(.trailing)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .font(AppTypography.body)
                                    .foregroundStyle(AppColors.label)
                            }
                            Divider().padding(.leading, AppConstants.UI.padding)
                            ProfileFieldRow(label: "Email") {
                                TextField("Email", text: $email)
                                    .multilineTextAlignment(.trailing)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .font(AppTypography.body)
                                    .foregroundStyle(AppColors.label)
                            }
                        }
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
                    }

                    // CHANGE PASSWORD section
                    VStack(alignment: .leading, spacing: AppConstants.UI.spacingSM) {
                        Text("CHANGE PASSWORD")
                            .font(AppTypography.sectionHeader)
                            .foregroundStyle(AppColors.label2)

                        VStack(spacing: 0) {
                            ProfileSecureRow(placeholder: "Current Password", text: $currentPassword)
                                .textContentType(.password)
                            Divider().padding(.leading, AppConstants.UI.padding)
                            ProfileSecureRow(placeholder: "New Password", text: $newPassword)
                                .textContentType(.newPassword)
                            Divider().padding(.leading, AppConstants.UI.padding)
                            ProfileSecureRow(placeholder: "Confirm New Password", text: $confirmPassword)
                                .textContentType(.newPassword)
                        }
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))

                        Text("Leave blank to keep your current password.")
                            .font(AppTypography.caption1)
                            .foregroundStyle(AppColors.label2)
                            .padding(.horizontal, AppConstants.UI.spacingSM)
                    }
                }
                .padding(.horizontal, AppConstants.UI.padding)
                .padding(.vertical, AppConstants.UI.spacing20)
            }
            .background(AppColors.background)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppColors.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!hasChanges || !isValid || isLoading)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.accent)
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
                if email != currentEmail {
                    Text("Your profile has been updated. Please verify your new email address.")
                } else {
                    Text("Your profile has been updated successfully.")
                }
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
                    password: passwordToSend,
                    currentPassword: currentPassword.isEmpty ? nil : currentPassword
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

private struct ProfileFieldRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack {
            Text(label)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.label2)
            Spacer()
            content()
        }
        .padding(.horizontal, AppConstants.UI.padding)
        .padding(.vertical, 14)
    }
}

private struct ProfileSecureRow: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        SecureField(placeholder, text: $text)
            .font(AppTypography.body)
            .foregroundStyle(AppColors.label)
            .padding(.horizontal, AppConstants.UI.padding)
            .padding(.vertical, 14)
    }
}

#Preview {
    EditProfileView(currentUsername: "Ankush", currentEmail: "ankush@example.com")
}
