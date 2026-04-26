import SwiftUI

struct InviteParentView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var auth = AuthManager.shared

    @State private var accessLevel: AccessLevelChoice = .viewOnly
    @State private var inviteCode: String? = nil
    @State private var expiresAt: String? = nil
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showShareSheet = false

    enum AccessLevelChoice: String, CaseIterable {
        case viewOnly = "view_only"
        case full     = "full"

        var label: String {
            switch self {
            case .viewOnly: return "View Only"
            case .full:     return "Full Access"
            }
        }
        var description: String {
            switch self {
            case .viewOnly: return "Can track the bus and see child status. Cannot mark absences or send invites."
            case .full:     return "Same permissions as you. Can mark absences and manage the child's route."
            }
        }
        var icon: String {
            switch self { case .viewOnly: return "eye.fill"; case .full: return "person.fill.checkmark" }
        }
        var color: Color {
            switch self { case .viewOnly: return Color(hex: "2F80ED"); case .full: return Color(hex: "2ECC71") }
        }
    }

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
                    Text("Invite Parent")
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
                                .fill(Color(hex: "F5A623"))
                                .frame(width: 72, height: 72)
                                .shadow(color: Color(hex: "F5A623").opacity(0.4), radius: 12, y: 4)
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 32))
                                .foregroundStyle(.white)
                        }
                        .padding(.top, 24)

                        VStack(spacing: 6) {
                            Text("Grant Parent Access")
                                .font(.system(size: 24, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                            Text("Choose what the secondary parent\ncan see and do.")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundStyle(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }

                        // Access level picker
                        if inviteCode == nil {
                            VStack(spacing: 12) {
                                Text("ACCESS LEVEL")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.7))
                                    .tracking(2)

                                ForEach(AccessLevelChoice.allCases, id: \.self) { choice in
                                    AccessLevelCard(
                                        choice: choice,
                                        isSelected: accessLevel == choice
                                    ) { accessLevel = choice }
                                }
                            }
                            .padding(.horizontal, 24)

                            if let err = errorMessage {
                                Text(err)
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundStyle(Color(hex: "FF3B30"))
                                    .padding(10)
                                    .background(.white.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }

                            Button {
                                Task { await generateCode() }
                            } label: {
                                HStack {
                                    if isLoading { ProgressView().tint(.white) }
                                    else {
                                        Image(systemName: "link.badge.plus")
                                        Text("Generate Invite Code")
                                    }
                                }
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(Color(hex: "F5A623"))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: Color(hex: "F5A623").opacity(0.4), radius: 8, y: 4)
                            }
                            .disabled(isLoading)
                            .padding(.horizontal, 24)

                        } else {
                            // Invite code card
                            InviteCodeCard(
                                code: inviteCode!,
                                accessLevel: accessLevel,
                                expiresAt: expiresAt ?? "24 hours"
                            )
                            .padding(.horizontal, 24)

                            Button {
                                showShareSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share Code")
                                }
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(Color(hex: "2F80ED"))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .padding(.horizontal, 24)

                            Button {
                                inviteCode = nil
                                errorMessage = nil
                            } label: {
                                Text("Generate Another Code")
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                    }
                    .padding(.bottom, 40)
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
        .sheet(isPresented: $showShareSheet) {
            if let code = inviteCode {
                ShareSheet(items: [
                    "You've been invited to track your child's bus on MagicBusRoute!\n\nUse invite code: \(code)\n\nDownload the app and tap \"Have an invite code?\" on the welcome screen.\n\nCode expires in 24 hours."
                ])
            }
        }
    }

    private func generateCode() async {
        isLoading = true
        errorMessage = nil
        guard let url = URL(string: "http://127.0.0.1:8000/parent/invite"),
              let token = auth.accessToken else { isLoading = false; return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONEncoder().encode(["access_level": accessLevel.rawValue])

        do {
            let (data, _) = try await NetworkSession.pinned.data(for: request)
            if let json = try? JSONDecoder().decode(InviteCodeResponse.self, from: data) {
                inviteCode = json.invite_code
                expiresAt  = json.expires_at
                SecurityMonitor.shared.report(.inviteSent, context: ["access_level": accessLevel.rawValue])
            } else {
                errorMessage = "Failed to generate code. Try again."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Supporting types

private struct InviteCodeResponse: Decodable {
    let invite_code: String
    let access_level: String
    let expires_at: String
}

// MARK: - Access Level Card

private struct AccessLevelCard: View {
    let choice: InviteParentView.AccessLevelChoice
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(choice.color)
                        .frame(width: 44, height: 44)
                    Image(systemName: choice.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(choice.label)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(choice.description)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? choice.color : .white.opacity(0.4))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(isSelected ? 0.25 : 0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(isSelected ? choice.color.opacity(0.8) : .white.opacity(0.2), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Invite Code Card

private struct InviteCodeCard: View {
    let code: String
    let accessLevel: InviteParentView.AccessLevelChoice
    let expiresAt: String

    var body: some View {
        VStack(spacing: 16) {
            Text("INVITE CODE")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
                .tracking(2.5)

            Text(code)
                .font(.system(size: 40, weight: .heavy, design: .monospaced))
                .foregroundStyle(.white)
                .kerning(8)

            HStack(spacing: 8) {
                Image(systemName: accessLevel.icon)
                    .foregroundStyle(accessLevel.color)
                Text(accessLevel.label)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                Text("·")
                    .foregroundStyle(.white.opacity(0.4))
                Image(systemName: "clock")
                    .foregroundStyle(.white.opacity(0.6))
                Text("Expires in 24 hrs")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(accessLevel.color.opacity(0.6), lineWidth: 1.5)
                )
        )
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
