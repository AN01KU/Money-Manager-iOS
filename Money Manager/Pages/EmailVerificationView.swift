//
//  EmailVerificationView.swift
//  Money Manager
//

import SwiftUI

struct EmailVerificationView: View {
    let email: String
    var onVerified: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.authService) private var authService
    @State private var code = ""
    @State private var isVerifying = false
    @State private var isResending = false
    @State private var errorMessage: String?
    @State private var resendCooldown = 0
    @State private var resendTimer: Timer?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    headerSection
                    codeSection
                    actionSection
                }
                .padding(24)
            }
            .dismissKeyboardOnScroll()
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .alert("Verification Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope.badge.fill")
                .font(.system(size: 60))
                .foregroundStyle(AppColors.accent)

            Text("Check Your Email")
                .font(.title)
                .fontWeight(.bold)

            Text("We sent a 6-digit code to\n**\(email)**\n\nEnter it below to verify your account.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    private var codeSection: some View {
        VStack(spacing: 12) {
            TextField("6-digit code", text: $code)
                .textFieldStyle(.plain)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .font(.title2.monospacedDigit())
                .multilineTextAlignment(.center)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(.rect(cornerRadius: 12))
                .onChange(of: code) { _, newValue in
                    // Strip non-digits and cap at 6
                    code = String(newValue.filter(\.isNumber).prefix(6))
                }

            if !code.isEmpty && code.count < 6 {
                Text("\(6 - code.count) more digit\(6 - code.count == 1 ? "" : "s") needed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var actionSection: some View {
        VStack(spacing: 16) {
            Button {
                verify()
            } label: {
                Group {
                    if isVerifying {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Verify Email")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(code.count == 6 ? AppColors.accent : Color.gray)
                .foregroundStyle(.white)
                .clipShape(.rect(cornerRadius: 12))
            }
            .disabled(code.count != 6 || isVerifying)

            resendButton
        }
    }

    private var resendButton: some View {
        Button {
            resend()
        } label: {
            if resendCooldown > 0 {
                Text("Resend code in \(resendCooldown)s")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if isResending {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Text("Resend code")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.accent)
            }
        }
        .disabled(isResending || resendCooldown > 0)
    }

    private func verify() {
        isVerifying = true
        errorMessage = nil

        Task {
            do {
                try await authService.verifyEmail(code: code)
                onVerified?()
                dismiss()
            } catch {
                errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
            }
            isVerifying = false
        }
    }

    private func resend() {
        isResending = true
        errorMessage = nil

        Task {
            do {
                try await authService.resendVerification()
                startResendCooldown()
            } catch {
                errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
            }
            isResending = false
        }
    }

    private func startResendCooldown() {
        resendCooldown = 60
        resendTimer?.invalidate()
        resendTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                resendCooldown -= 1
                if resendCooldown <= 0 {
                    resendTimer?.invalidate()
                    resendTimer = nil
                }
            }
        }
    }
}

#Preview {
    EmailVerificationView(email: "user@example.com")
        .environment(\.authService, MockAuthService.shared)
}
