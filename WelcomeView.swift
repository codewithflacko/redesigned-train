import SwiftUI

// MARK: - Hex Color Helper
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 1, 1, 1)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Portal Destination
enum PortalDestination: Hashable {
    case parent, dispatch, driver, admin
}

// MARK: - Welcome View
struct WelcomeView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                // Sky gradient
                LinearGradient(
                    colors: [
                        Color(hex: "4A90D9"),
                        Color(hex: "7DBCE8"),
                        Color(hex: "C5E8F5")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Floating clouds
                CloudsView()

                VStack(spacing: 0) {
                    Spacer().frame(maxHeight: 32)

                    // Bus scene
                    BusSceneView()
                        .frame(height: 130)
                        .padding(.horizontal, 16)
                        .clipped()

                    Spacer().frame(height: 20)

                    // App branding
                    VStack(spacing: 6) {
                        Text("Magic Bus Route")
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.25), radius: 3, y: 2)

                        Text("Safe rides, every time.")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                    }

                    Spacer().frame(maxHeight: 32)

                    // Portal buttons — 2x2 grid
                    VStack(spacing: 12) {
                        Text("SELECT YOUR PORTAL")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(2.5)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            PortalSquareCard(
                                title: "Parent",
                                subtitle: "Track your child",
                                icon: "figure.2.and.child.holdinghands",
                                color: Color(hex: "2ECC71")
                            ) { path.append(PortalDestination.parent) }

                            PortalSquareCard(
                                title: "Dispatch",
                                subtitle: "Monitor routes",
                                icon: "map.fill",
                                color: Color(hex: "2F80ED")
                            ) { path.append(PortalDestination.dispatch) }

                            PortalSquareCard(
                                title: "Driver",
                                subtitle: "Manage your route",
                                icon: "steeringwheel",
                                color: Color(hex: "F5A623")
                            ) { path.append(PortalDestination.driver) }

                            PortalSquareCard(
                                title: "Admin",
                                subtitle: "School overview",
                                icon: "building.columns.fill",
                                color: Color(hex: "8E44AD")
                            ) { path.append(PortalDestination.admin) }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationDestination(for: PortalDestination.self) { destination in
                switch destination {
                case .parent:   ParentLoginView()
                case .dispatch: DispatchLoginView()
                case .driver:   DriverLoginView()
                case .admin:    AdminLoginView()
                }
            }
        }
    }
}

// MARK: - Floating Portal Card
struct FloatingPortalCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    var action: () -> Void = {}

    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(color)
                        .frame(width: 46, height: 46)
                        .shadow(color: color.opacity(0.4), radius: 6, y: 3)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.white.opacity(0.75))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(.white.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(.white.opacity(0.35), lineWidth: 1)
                    )
            )
            .scaleEffect(pressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeIn(duration: 0.1)) { pressed = true } }
                .onEnded   { _ in withAnimation(.spring(response: 0.3)) { pressed = false } }
        )
    }
}

// MARK: - Portal Square Card (2x2 grid tile)
struct PortalSquareCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    var action: () -> Void = {}

    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(color)
                        .frame(width: 54, height: 54)
                        .shadow(color: color.opacity(0.45), radius: 8, y: 4)
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
                VStack(spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white.opacity(0.18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(color.opacity(0.5), lineWidth: 1.5)
                    )
            )
            .scaleEffect(pressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeIn(duration: 0.1)) { pressed = true } }
                .onEnded   { _ in withAnimation(.spring(response: 0.3)) { pressed = false } }
        )
    }
}

// MARK: - Bus Scene
struct BusSceneView: View {
    @State private var busOffset: CGFloat = -240

    var body: some View {
        ZStack(alignment: .bottom) {
            // Road
            ZStack {
                Rectangle()
                    .fill(Color(hex: "4A4A4A"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)

                // Dashed center line
                HStack(spacing: 18) {
                    ForEach(0..<12, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.white.opacity(0.55))
                            .frame(width: 24, height: 4)
                    }
                }
            }

            // Bus
            BusView()
                .offset(x: busOffset, y: -17)
                .onAppear {
                    withAnimation(.spring(response: 1.0, dampingFraction: 0.75)) {
                        busOffset = 0
                    }
                }
        }
    }
}

// MARK: - Bus
struct BusView: View {
    // Fixed child data: (hair, skin, shirt)
    let kidData: [(Color, Color, Color)] = [
        (Color(hex: "3D2B1F"), Color(hex: "FFCC80"), Color(hex: "E53935")),
        (Color(hex: "F4C430"), Color(hex: "FFB87A"), Color(hex: "1565C0")),
        (Color(hex: "1A1A1A"), Color(hex: "C68642"), Color(hex: "2E7D32")),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main body
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: "FFD100"))
                .frame(width: 190, height: 60)

            // Front cab (slightly darker yellow)
            HStack(spacing: 0) {
                Spacer()
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 10,
                    topTrailingRadius: 10
                )
                .fill(Color(hex: "EAB800"))
                .frame(width: 46, height: 60)
            }
            .frame(width: 190)

            // Black window stripe
            Rectangle()
                .fill(Color(hex: "2C2C2C"))
                .frame(width: 190, height: 6)
                .offset(y: 10)

            // "SCHOOL BUS" text
            Text("SCHOOL BUS")
                .font(.system(size: 6, weight: .black))
                .foregroundColor(Color(hex: "1A1A1A").opacity(0.5))
                .offset(y: 21)

            // Windows row
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    ChildWindowView(
                        hairColor: kidData[i].0,
                        skinColor: kidData[i].1,
                        shirtColor: kidData[i].2
                    )
                }

                Spacer()

                // Driver window
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(hex: "B8DCF5"))
                    .frame(width: 24, height: 22)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(Color(hex: "333333"), lineWidth: 1.5)
                    )
            }
            .padding(.horizontal, 12)
            .offset(y: -14)

            // Headlight
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "FFFDE7"))
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .strokeBorder(Color(hex: "CCCC00"), lineWidth: 0.5)
                )
                .frame(width: 10, height: 7)
                .offset(x: 82, y: 12)

            // Stop sign dot
            Circle()
                .fill(Color(hex: "E53935"))
                .frame(width: 9, height: 9)
                .offset(x: -90, y: -3)

            // Wheels
            HStack(spacing: 110) {
                WheelView()
                WheelView()
            }
            .offset(y: 10)
        }
    }
}

// MARK: - Child Window
struct ChildWindowView: View {
    let hairColor: Color
    let skinColor: Color
    let shirtColor: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(hex: "C8E8F5"))
                .frame(width: 30, height: 26)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(Color(hex: "333333"), lineWidth: 1.5)
                )

            VStack(spacing: 0) {
                // Hair
                Capsule()
                    .fill(hairColor)
                    .frame(width: 14, height: 7)
                    .offset(y: 3)
                // Head
                Circle()
                    .fill(skinColor)
                    .frame(width: 12, height: 12)
                // Shirt hint
                Capsule()
                    .fill(shirtColor)
                    .frame(width: 16, height: 5)
            }
            .offset(y: 4)
        }
    }
}

// MARK: - Wheel
struct WheelView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "1A1A1A"))
                .frame(width: 28, height: 28)
            Circle()
                .fill(Color(hex: "777777"))
                .frame(width: 16, height: 16)
            Circle()
                .fill(Color(hex: "CCCCCC"))
                .frame(width: 7, height: 7)
        }
    }
}

// MARK: - Clouds
struct CloudsView: View {
    var body: some View {
        VStack {
            HStack {
                CloudShape()
                    .fill(.white.opacity(0.55))
                    .frame(width: 110, height: 44)
                    .offset(x: 16, y: 64)

                Spacer()

                CloudShape()
                    .fill(.white.opacity(0.45))
                    .frame(width: 140, height: 54)
                    .offset(x: -8, y: 36)
            }
            Spacer()
        }
        .ignoresSafeArea()
    }
}

struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        path.addEllipse(in: CGRect(x: w * 0.05, y: h * 0.35, width: w * 0.45, height: h * 0.65))
        path.addEllipse(in: CGRect(x: w * 0.28, y: h * 0.05, width: w * 0.38, height: h * 0.60))
        path.addEllipse(in: CGRect(x: w * 0.55, y: h * 0.25, width: w * 0.40, height: h * 0.65))
        return path
    }
}

// MARK: - Preview
#Preview {
    WelcomeView()
}
