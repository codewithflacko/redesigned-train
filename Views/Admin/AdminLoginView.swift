import SwiftUI

struct AdminLoginView: View {
    @State private var email         = ""
    @State private var adminID       = ""
    @State private var password      = ""
    @State private var isLoading     = false
    @State private var showDashboard = false
    @State private var authError: String? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "F3E8FF"), Color(hex: "FAF5FF")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Nav
                    HStack {
                        Button(action: { dismiss() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("Back")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(Color(hex: "8E44AD"))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    // Icon + title
                    VStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "8E44AD").opacity(0.12))
                                .frame(width: 96, height: 96)
                            Circle()
                                .fill(Color(hex: "8E44AD").opacity(0.07))
                                .frame(width: 116, height: 116)
                            Image(systemName: "building.columns.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Color(hex: "8E44AD"))
                        }
                        .padding(.top, 24)

                        Text("Admin Portal")
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(hex: "1A1A2E"))

                        Text("School administration & oversight")
                            .font(.system(size: 15, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 36)

                    // Fields
                    VStack(spacing: 16) {
                        InputField(label: "School Email", placeholder: "admin@riverside.edu",
                                   icon: "envelope", text: $email, keyboardType: .emailAddress)

                        InputField(label: "Admin ID", placeholder: "e.g. ADM-001",
                                   icon: "person.badge.key.fill", text: $adminID)

                        SecureInputField(label: "Password", placeholder: "••••••••",
                                         icon: "lock", text: $password)

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

                        Button(action: handleLogin) {
                            ZStack {
                                if isLoading { ProgressView().tint(.white) }
                                else {
                                    Text("Sign In")
                                        .font(.system(size: 17, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(hex: "8E44AD"))
                                    .shadow(color: Color(hex: "8E44AD").opacity(0.35), radius: 10, y: 5)
                            )
                        }
                        .disabled(isLoading)

                        Text("Authorized school personnel only.")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showDashboard) {
            AdminDashboardView()
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
                try await AuthManager.shared.login(email: email, password: password, role: .admin)
                isLoading = false
                showDashboard = true
            } catch {
                isLoading = false
                authError = error.localizedDescription
            }
        }
    }
}

#Preview {
    AdminLoginView()
}
