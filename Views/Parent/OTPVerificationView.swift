import SwiftUI

struct OTPVerificationView: View {
    let role: UserRole
    var onSuccess: () -> Void
    var onCancel: () -> Void

    @ObservedObject private var auth = AuthManager.shared
    @State private var digits: [String] = Array(repeating: "", count: 6)
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false
    @State private var isResending: Bool = false
    @FocusState private var focusedIndex: Int?

    private var code: String { digits.joined() }
    private var isComplete: Bool { code.count == 6 }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "4A90D9"), Color(hex: "7DBCE8"), Color(hex: "C5E8F5")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Demo code banner
                if let demo = auth.demoOTPCode {
                    Button {
                        autofill(demo)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.black.opacity(0.6))
                            Text("Demo Code: ")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(.black.opacity(0.7))
                            + Text(demo)
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                                .foregroundStyle(.black)
                            Text("— Tap to fill")
                                .font(.system(size: 12, design: .rounded))
                                .foregroundStyle(.black.opacity(0.5))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(hex: "FFD700").opacity(0.9))
                        .clipShape(Capsule())
                    }
                    .padding(.top, 60)
                }

                Spacer()

                VStack(spacing: 28) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(hex: "2ECC71"))
                            .frame(width: 72, height: 72)
                            .shadow(color: Color(hex: "2ECC71").opacity(0.4), radius: 12, y: 4)
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(.white)
                    }

                    VStack(spacing: 8) {
                        Text("2-Step Verification")
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.2), radius: 2, y: 1)

                        Text("Enter the 6-digit code sent to\nyour registered contact.")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                    }

                    // 6-digit boxes
                    HStack(spacing: 10) {
                        ForEach(0..<6, id: \.self) { i in
                            OTPBox(
                                digit: $digits[i],
                                isFocused: focusedIndex == i
                            )
                            .focused($focusedIndex, equals: i)
                            .onChange(of: digits[i]) { _, val in
                                handleDigitChange(at: i, value: val)
                            }
                        }
                    }

                    // Error
                    if let err = errorMessage {
                        Text(err)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(Color(hex: "FF3B30"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.white.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Verify button
                    Button {
                        Task { await verify() }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Verify")
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isComplete ? Color(hex: "2ECC71") : Color.white.opacity(0.25))
                        )
                    }
                    .disabled(!isComplete || isLoading)
                    .padding(.horizontal, 24)

                    // Resend + cancel
                    HStack(spacing: 24) {
                        Button {
                            Task { await resend() }
                        } label: {
                            HStack(spacing: 4) {
                                if isResending { ProgressView().tint(.white).scaleEffect(0.7) }
                                Text("Resend Code")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                        .disabled(isResending)

                        Button {
                            auth.clearOTPState()
                            onCancel()
                        } label: {
                            Text("Cancel")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 60)

                Spacer()
            }
        }
        .onAppear { focusedIndex = 0 }
    }

    // MARK: - Actions

    private func handleDigitChange(at index: Int, value: String) {
        // Keep only last character, digits only
        let filtered = value.filter { $0.isNumber }
        if filtered.count > 1 {
            digits[index] = String(filtered.suffix(1))
        } else {
            digits[index] = filtered
        }
        errorMessage = nil

        // Auto-advance
        if !digits[index].isEmpty, index < 5 {
            focusedIndex = index + 1
        }
        // Auto-submit when all 6 filled
        if isComplete { Task { await verify() } }
    }

    private func autofill(_ code: String) {
        let chars = Array(code.prefix(6))
        for i in 0..<min(chars.count, 6) {
            digits[i] = String(chars[i])
        }
    }

    private func verify() async {
        guard isComplete else { return }
        isLoading = true
        errorMessage = nil
        do {
            try await auth.verifyOTP(code: code)
            onSuccess()
        } catch AuthError.invalidCredentials {
            errorMessage = "Incorrect code. Please try again."
            digits = Array(repeating: "", count: 6)
            focusedIndex = 0
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func resend() async {
        isResending = true
        guard let email = auth.pendingEmail, let r = auth.pendingRole else { isResending = false; return }
        try? await auth.login(email: email, password: "", role: r)
        digits = Array(repeating: "", count: 6)
        focusedIndex = 0
        isResending = false
    }
}

// MARK: - OTP Box

private struct OTPBox: View {
    @Binding var digit: String
    let isFocused: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(isFocused ? 0.35 : 0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isFocused ? Color.white : Color.white.opacity(0.3), lineWidth: isFocused ? 2 : 1)
                )
                .frame(width: 46, height: 56)

            TextField("", text: $digit)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 46, height: 56)
        }
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}
