import SwiftUI

struct DispatchLoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var badgeID = ""
    @State private var isLoading = false
    @State private var showDashboard = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "E8F0FE"), Color(hex: "F5F8FF")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    HStack {
                        Button(action: { dismiss() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("Back")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(Color(hex: "2F80ED"))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    VStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "2F80ED").opacity(0.12))
                                .frame(width: 96, height: 96)
                            Circle()
                                .fill(Color(hex: "2F80ED").opacity(0.07))
                                .frame(width: 116, height: 116)
                            Image(systemName: "map.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Color(hex: "2F80ED"))
                        }
                        .padding(.top, 24)

                        Text("Dispatch Portal")
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(hex: "1A1A2E"))

                        Text("Monitor all routes in real time")
                            .font(.system(size: 15, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 36)

                    VStack(spacing: 18) {
                        InputField(label: "Email", placeholder: "dispatch@schooldistrict.gov",
                                   icon: "envelope", text: $email, keyboardType: .emailAddress)

                        InputField(label: "Dispatcher Badge ID", placeholder: "e.g. D-1042",
                                   icon: "shield.fill", text: $badgeID)

                        SecureInputField(label: "Password", placeholder: "••••••••",
                                         icon: "lock", text: $password)

                        Button(action: {
                            isLoading = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                isLoading = false
                                showDashboard = true
                            }
                        }) {
                            ZStack {
                                if isLoading { ProgressView().tint(.white) }
                                else {
                                    Text("Sign In to Dispatch")
                                        .font(.system(size: 17, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(hex: "2F80ED"))
                                    .shadow(color: Color(hex: "2F80ED").opacity(0.35), radius: 10, y: 5)
                            )
                        }
                        .disabled(isLoading)

                        Text("Authorized personnel only.\nUnauthorized access is prohibited.")
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
            DispatchDashboardView()
        }
    }
}

#Preview {
    DispatchLoginView()
}
