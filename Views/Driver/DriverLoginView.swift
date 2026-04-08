import SwiftUI

struct DriverLoginView: View {
    @State private var driverID = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var selectedDriver: Driver? = nil
    @State private var showDashboard = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "FFF8ED"), Color(hex: "FFFDF5")],
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
                            .foregroundColor(Color(hex: "F5A623"))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    // Icon + title
                    VStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "F5A623").opacity(0.12))
                                .frame(width: 96, height: 96)
                            Circle()
                                .fill(Color(hex: "F5A623").opacity(0.07))
                                .frame(width: 116, height: 116)
                            Image(systemName: "steeringwheel")
                                .font(.system(size: 40))
                                .foregroundColor(Color(hex: "F5A623"))
                        }
                        .padding(.top, 24)

                        Text("Driver Portal")
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(hex: "1A1A2E"))

                        Text("Select your profile to start your shift")
                            .font(.system(size: 15, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 28)

                    // Driver selector
                    VStack(spacing: 10) {
                        Text("WHO'S DRIVING TODAY?")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                            .tracking(1.5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)

                        ForEach(Driver.sampleDrivers) { driver in
                            DriverProfileCard(
                                driver: driver,
                                isSelected: selectedDriver?.id == driver.id
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedDriver = driver
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 24)

                    // Credentials (appear when driver selected)
                    if selectedDriver != nil {
                        VStack(spacing: 16) {
                            InputField(label: "Driver ID", placeholder: "e.g. DRV-2048",
                                       icon: "person.text.rectangle.fill", text: $driverID)
                            SecureInputField(label: "Password", placeholder: "••••••••",
                                             icon: "lock", text: $password)

                            Button(action: handleLogin) {
                                ZStack {
                                    if isLoading { ProgressView().tint(.white) }
                                    else {
                                        Text("Start My Shift")
                                            .font(.system(size: 17, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(hex: "F5A623"))
                                        .shadow(color: Color(hex: "F5A623").opacity(0.35), radius: 10, y: 5)
                                )
                            }
                            .disabled(isLoading)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showDashboard) {
            if let driver = selectedDriver {
                DriverDashboardView(driver: driver)
            }
        }
    }

    private func handleLogin() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            isLoading = false
            showDashboard = true
        }
    }
}

// MARK: - Driver Profile Card
struct DriverProfileCard: View {
    let driver: Driver
    let isSelected: Bool
    let action: () -> Void

    private var routeStats: String {
        let stops = driver.route.totalStops
        let students = driver.route.totalStudents
        return "\(stops) stops · \(students) students"
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(isSelected ? driver.avatarColor : driver.avatarColor.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Text(String(driver.name.components(separatedBy: " ").last?.prefix(1) ?? "D"))
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(isSelected ? .white : driver.avatarColor)
                }
                .shadow(color: isSelected ? driver.avatarColor.opacity(0.4) : .clear, radius: 6, y: 2)

                VStack(alignment: .leading, spacing: 3) {
                    Text(driver.name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "1A1A2E"))
                    Text("Bus #\(driver.busNumber)  ·  \(driver.routeName)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    Text(routeStats)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Route status
                VStack(spacing: 4) {
                    Circle()
                        .fill(driver.route.status.color)
                        .frame(width: 10, height: 10)
                    Text(shortStatus(driver.route.status))
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(driver.route.status.color)
                }

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(driver.avatarColor)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(
                                isSelected ? driver.avatarColor : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .shadow(
                        color: isSelected ? driver.avatarColor.opacity(0.2) : .black.opacity(0.07),
                        radius: isSelected ? 12 : 6,
                        y: 3
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func shortStatus(_ status: RouteStatus) -> String {
        switch status {
        case .notStarted: return "Ready"
        case .inProgress: return "Active"
        case .paused:     return "Paused"
        case .delayed:    return "Delayed"
        case .completed:  return "Done"
        }
    }
}

#Preview {
    DriverLoginView()
}
