import SwiftUI

struct AcceptInviteView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var inviteCode = ""
    @State private var email      = ""
    @State private var password   = ""
    @State private var isLoading  = false
    @State private var errorMessage: String? = nil
    @State private var showDashboard = false

    var body: some View {
        VStack(spacing: 0) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(10)
                            .background(.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text("Join via Invite")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Color.clear.frame(width: 36)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                ScrollView {
                    VStack(spacing: 24) {

                        // Icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(hex: "2ECC71"))
                                .frame(width: 72, height: 72)
                                .shadow(color: Color(hex: "2ECC71").opacity(0.4), radius: 12, y: 4)
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 30))
                                .foregroundStyle(.white)
                        }
                        .padding(.top, 24)

                        VStack(spacing: 6) {
                            Text("You've Been Invited!")
                                .font(.system(size: 24, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                            Text("Enter the code a parent shared with you\nand create your account.")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundStyle(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }

                        // Form
                        VStack(spacing: 14) {
                            InviteField(
                                icon: "ticket.fill",
                                placeholder: "Invite Code (e.g. AB1C2D)",
                                text: $inviteCode,
                                isUppercase: true
                            )

                            InviteField(
                                icon: "envelope.fill",
                                placeholder: "Your Email",
                                text: $email,
                                keyboardType: .emailAddress
                            )

                            InviteField(
                                icon: "lock.fill",
                                placeholder: "Create a Password",
                                text: $password,
                                isSecure: true
                            )
                        }
                        .padding(.horizontal, 24)

                        if let err = errorMessage {
                            Text(err)
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(Color(hex: "FF3B30"))
                                .padding(10)
                                .background(.white.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding(.horizontal, 24)
                        }

                        Button {
                            Task { await acceptInvite() }
                        } label: {
                            HStack {
                                if isLoading { ProgressView().tint(.white) }
                                else {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Join MagicBusRoute")
                                }
                            }
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(isFormValid ? Color(hex: "2ECC71") : Color.white.opacity(0.25))
                            )
                            .shadow(
                                color: isFormValid ? Color(hex: "2ECC71").opacity(0.4) : .clear,
                                radius: 8, y: 4
                            )
                        }
                        .disabled(!isFormValid || isLoading)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            LinearGradient(
                colors: [Color(hex: "4A90D9"), Color(hex: "7DBCE8"), Color(hex: "C5E8F5")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .fullScreenCover(isPresented: $showDashboard) {
            ParentDashboardView()
        }
    }

    private var isFormValid: Bool {
        inviteCode.count >= 5 && !email.isEmpty && password.count >= 6
    }

    private func acceptInvite() async {
        isLoading = true
        errorMessage = nil

        guard let url = URL(string: "http://127.0.0.1:8000/parent/invite/accept") else {
            isLoading = false; return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "invite_code": inviteCode.uppercased(),
            "email":       email.lowercased(),
            "password":    password,
        ]
        request.httpBody = try? JSONEncoder().encode(body)

        do {
            let (data, response) = try await NetworkSession.pinned.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }

            switch http.statusCode {
            case 200:
                let payload = try JSONDecoder().decode(LoginResponsePayload.self, from: data)
                if let token = payload.access_token, let uid = payload.user_id {
                    await MainActor.run {
                        AuthManager.shared.acceptInviteLogin(token: token, userId: uid, email: email)
                    }
                    SecurityMonitor.shared.report(.inviteAccepted, context: ["email": email])
                    showDashboard = true
                    dismiss()
                }
            case 400:
                errorMessage = "Invalid or expired invite code."
            default:
                errorMessage = "Something went wrong. Try again."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Invite Field

private struct InviteField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    var isUppercase: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 20)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .autocapitalization(isUppercase ? .allCharacters : .none)
                        .disableAutocorrection(true)
                }
            }
            .font(.system(size: 15, design: .rounded))
            .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.white.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                )
        )
        .onChange(of: text) { _, val in
            if isUppercase { text = val.uppercased() }
        }
    }
}
