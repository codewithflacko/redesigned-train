import SwiftUI

// MARK: - AfterHoursManager

final class AfterHoursManager: ObservableObject {
    static let shared = AfterHoursManager()
    private init() {}

    @Published private(set) var isAfterHours: Bool = AfterHoursManager.check()

    private var timer: Timer?

    func startMonitoring() {
        isAfterHours = AfterHoursManager.check()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            let result = AfterHoursManager.check()
            DispatchQueue.main.async { self?.isAfterHours = result }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    // After hours = 7:00pm (19:00) through 4:59am
    static func check() -> Bool {
        #if DEBUG
        return false
        #else
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 19 || hour < 5
        #endif
    }
}

// MARK: - AfterHoursView

struct AfterHoursView: View {
    @StateObject private var manager = AfterHoursManager.shared

    var body: some View {
        if manager.isAfterHours {
            AfterHoursScreen()
                .transition(.opacity)
                .onAppear { manager.startMonitoring() }
        }
    }
}

// MARK: - AfterHoursScreen

private struct AfterHoursScreen: View {
    @State private var starOpacity: Double = 0.4

    var body: some View {
        ZStack {
            // Night sky gradient
            LinearGradient(
                colors: [
                    Color(hex: "0D0D2B"),
                    Color(hex: "1A1A4E"),
                    Color(hex: "2C2C6E"),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Stars
            StarsView(opacity: starOpacity)

            // Moon
            MoonView()

            VStack(spacing: 0) {
                Spacer().frame(maxHeight: 32)

                // Night bus scene
                NightBusSceneView()
                    .frame(height: 130)
                    .padding(.horizontal, 16)
                    .clipped()

                Spacer().frame(height: 20)

                // Branding
                VStack(spacing: 6) {
                    Text("Magic Bus Route")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.4), radius: 4, y: 2)

                    Text("Safe rides, every time.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer().frame(maxHeight: 32)

                // After hours card
                VStack(spacing: 16) {
                    // Moon badge
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(hex: "3D3D8F"))
                            .frame(width: 72, height: 72)
                            .shadow(color: Color(hex: "6666FF").opacity(0.3), radius: 12, y: 4)
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }

                    VStack(spacing: 8) {
                        Text("We're Closed for the Night")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text("See you during school hours!")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                    }

                    // Back open badge
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "FFD700"))
                        Text("Back online at 5:00 AM")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(.white.opacity(0.1))
                            .overlay(Capsule().strokeBorder(.white.opacity(0.2), lineWidth: 1))
                    )
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 28)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                starOpacity = 0.9
            }
        }
    }
}

// MARK: - Night Bus Scene

private struct NightBusSceneView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            // Dark road
            ZStack {
                Rectangle()
                    .fill(Color(hex: "1A1A1A"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)

                // Dim dashed line
                HStack(spacing: 18) {
                    ForEach(0..<12, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 24, height: 4)
                    }
                }
            }

            // Parked night bus (no drive-in animation)
            NightBusView()
                .offset(y: -17)
        }
    }
}

// MARK: - Night Bus (parked, lights off)

private struct NightBusView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main body — muted yellow
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: "8A7200"))
                .frame(width: 190, height: 60)

            // Front cab
            HStack(spacing: 0) {
                Spacer()
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 10,
                    topTrailingRadius: 10
                )
                .fill(Color(hex: "7A6400"))
                .frame(width: 46, height: 60)
            }
            .frame(width: 190)

            // Black window stripe
            Rectangle()
                .fill(Color(hex: "1A1A1A"))
                .frame(width: 190, height: 6)
                .offset(y: 10)

            // "SCHOOL BUS" text
            Text("SCHOOL BUS")
                .font(.system(size: 6, weight: .black))
                .foregroundColor(Color.white.opacity(0.15))
                .offset(y: 21)

            // Dark windows (kids asleep / no one inside)
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { _ in
                    SleepingWindowView()
                }
                Spacer()
                // Driver window — dark
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(hex: "1C2A3A"))
                    .frame(width: 24, height: 22)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(Color(hex: "222222"), lineWidth: 1.5)
                    )
            }
            .padding(.horizontal, 12)
            .offset(y: -14)

            // Headlight — off
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "333300"))
                .frame(width: 10, height: 7)
                .offset(x: 82, y: 12)

            // Wheels
            HStack(spacing: 110) {
                WheelView()
                WheelView()
            }
            .offset(y: 10)
        }
    }
}

// MARK: - Sleeping Window (dark, zzz)

private struct SleepingWindowView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(hex: "1C2A3A"))
                .frame(width: 30, height: 26)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(Color(hex: "222222"), lineWidth: 1.5)
                )
            Text("z")
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.25))
                .offset(y: -2)
        }
    }
}

// MARK: - Stars

private struct StarsView: View {
    let opacity: Double

    // Fixed star positions so they don't jump on re-render
    private let stars: [(CGFloat, CGFloat, CGFloat)] = [
        (0.08, 0.05, 2.5), (0.22, 0.12, 1.5), (0.45, 0.04, 3.0),
        (0.60, 0.09, 1.8), (0.78, 0.03, 2.2), (0.90, 0.14, 1.5),
        (0.15, 0.22, 1.8), (0.35, 0.18, 2.8), (0.55, 0.25, 1.5),
        (0.72, 0.20, 2.0), (0.88, 0.28, 1.5), (0.05, 0.35, 2.2),
        (0.30, 0.30, 1.5), (0.50, 0.08, 1.8), (0.68, 0.33, 3.0),
        (0.82, 0.10, 1.5), (0.95, 0.22, 2.0), (0.12, 0.42, 1.5),
    ]

    var body: some View {
        GeometryReader { geo in
            ForEach(0..<stars.count, id: \.self) { i in
                let (xRatio, yRatio, size) = stars[i]
                Circle()
                    .fill(Color.white)
                    .frame(width: size, height: size)
                    .position(
                        x: geo.size.width  * xRatio,
                        y: geo.size.height * yRatio
                    )
                    .opacity(opacity)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Moon

private struct MoonView: View {
    var body: some View {
        VStack {
            HStack {
                Spacer()
                ZStack {
                    Circle()
                        .fill(Color(hex: "FFD700").opacity(0.9))
                        .frame(width: 48, height: 48)
                        .blur(radius: 3)
                    Circle()
                        .fill(Color(hex: "FFE566"))
                        .frame(width: 40, height: 40)
                    // Crescent shadow
                    Circle()
                        .fill(Color(hex: "2C2C6E"))
                        .frame(width: 32, height: 32)
                        .offset(x: 10, y: -8)
                }
                .padding(.trailing, 36)
                .padding(.top, 72)
            }
            Spacer()
        }
        .ignoresSafeArea()
    }
}

// MARK: - Preview
#Preview {
    AfterHoursScreen()
}
