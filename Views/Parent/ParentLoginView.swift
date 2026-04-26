import SwiftUI

struct ParentLoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showDashboard = false
    @State private var showOTP = false
    @State private var authError: String? = nil
    @ObservedObject private var auth = AuthManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "E8F5E9"), Color(hex: "F9FFF9")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Nav bar
                    HStack {
                        Button(action: { dismiss() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("Back")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(Color(hex: "2ECC71"))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    // Icon + title
                    VStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "2ECC71").opacity(0.12))
                                .frame(width: 96, height: 96)
                            Circle()
                                .fill(Color(hex: "2ECC71").opacity(0.08))
                                .frame(width: 116, height: 116)
                            Image(systemName: "figure.2.and.child.holdinghands")
                                .font(.system(size: 42))
                                .foregroundColor(Color(hex: "2ECC71"))
                        }
                        .padding(.top, 24)

                        Text("Parent Portal")
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(hex: "1A1A2E"))

                        Text("Stay connected to every ride")
                            .font(.system(size: 15, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 36)

                    // Form card
                    VStack(spacing: 18) {
                        // Email
                        InputField(
                            label: "Email",
                            placeholder: "parent@email.com",
                            icon: "envelope",
                            text: $email,
                            keyboardType: .emailAddress
                        )

                        // Password
                        SecureInputField(
                            label: "Password",
                            placeholder: "••••••••",
                            icon: "lock",
                            text: $password
                        )

                        // Forgot
                        HStack {
                            Spacer()
                            Button("Forgot Password?") {}
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(Color(hex: "2ECC71"))
                        }

                        // Auth error banner
                        if let err = authError {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(Color(hex: "E74C3C"))
                                Text(err)
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundColor(Color(hex: "E74C3C"))
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(hex: "E74C3C").opacity(0.08))
                            )
                        }

                        // Sign In button
                        Button(action: handleLogin) {
                            ZStack {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Sign In")
                                        .font(.system(size: 17, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(hex: "2ECC71"))
                                    .shadow(color: Color(hex: "2ECC71").opacity(0.35), radius: 10, y: 5)
                            )
                        }
                        .disabled(isLoading)

                        // Divider
                        HStack {
                            Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 1)
                            Text("or")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 10)
                            Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 1)
                        }

                        // Create account
                        Button("Create Parent Account") {}
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(hex: "2ECC71"))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showDashboard) {
            ParentDashboardView()
        }
        .fullScreenCover(isPresented: $showOTP) {
            OTPVerificationView(role: .parent) {
                showOTP = false
                showDashboard = true
            } onCancel: {
                showOTP = false
            }
        }
    }

    private func handleLogin() {
        guard !email.isEmpty, !password.isEmpty else {
            authError = "Please enter your email and password."
            return
        }
        authError = nil
        isLoading = true
        Task {
            do {
                try await auth.login(email: email, password: password, role: .parent)
                isLoading = false
                if auth.requiresOTP {
                    showOTP = true
                } else {
                    showDashboard = true
                }
            } catch {
                isLoading = false
                authError = error.localizedDescription
            }
        }
    }
}

// MARK: - Reusable Input Fields
struct InputField: View {
    let label: String
    let placeholder: String
    let icon: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            )
        }
    }
}

struct SecureInputField: View {
    let label: String
    let placeholder: String
    let icon: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                SecureField(placeholder, text: $text)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            )
        }
    }
}

#Preview {
    ParentLoginView()
}
