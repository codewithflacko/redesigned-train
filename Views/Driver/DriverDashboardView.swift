import SwiftUI
import MapKit
import AVFoundation

// MARK: - Driver Dashboard
struct DriverDashboardView: View {
    @Binding var driver: Driver
    @StateObject private var voice          = VoiceAnnouncer()
    @ObservedObject private var chatStore   = ChatStore.shared
    @State private var showDrivingMode      = false
    @State private var showChat             = false
    @State private var showDelaySheet       = false
    @State private var showPauseSheet       = false
    @State private var showSickSheet        = false
    @State private var showReassignBanner   = false
    @State private var autoAlert: AutoAlert? = nil
    @State private var lastActivityDate     = Date()
    @State private var dispatchNotified     = false
    @Environment(\.dismiss) private var dismiss

    private let autoPauseThreshold: TimeInterval = 30
    private let autoDelayThreshold: TimeInterval = 60

    private var isRoutePaused: Bool  { if case .paused  = driver.route.status { return true }; return false }
    private var isRouteDelayed: Bool { if case .delayed = driver.route.status { return true }; return false }
    private var isRouteActive: Bool  { driver.route.status != .notStarted && driver.route.status != .completed }

    var body: some View {
        ZStack {
            Color(hex: "F0F4F8").ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    driverHeader
                    if let alert = autoAlert {
                        autoAlertBanner(alert)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    if showReassignBanner {
                        reassignBanner
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    routeControlsCard
                    statsGrid
                    progressCard
                    driverRouteMapCard
                    if isRouteActive { currentStopCard }
                    allStopsCard
                    Spacer().frame(height: 20)
                }
            }
        }
        .navigationBarHidden(true)
        .onChange(of: driver.route.status) { _, _ in
            AppState.shared.syncBusStatus(busNumber: driver.busNumber)
        }
        .onChange(of: driver.route.currentStopIndex) { _, newIdx in
            AppState.shared.driverCompletedStop(busNumber: driver.busNumber, newStopIndex: newIdx)
        }
        .task { await runAutoDetection() }
        .fullScreenCover(isPresented: $showDrivingMode) {
            DrivingModeView(driver: $driver, voice: voice) {
                showDrivingMode = false
            }
        }
        .sheet(isPresented: $showDelaySheet) {
            DelayReportSheet { reason in
                driver.route.status = .delayed(reason: reason)
                lastActivityDate = Date()
                autoAlert = nil
            }
        }
        .sheet(isPresented: $showPauseSheet) {
            PauseReportSheet { reason in
                driver.route.status = .paused(reason: reason)
                lastActivityDate = Date()
                autoAlert = nil
            }
        }
        .confirmationDialog("Report Sick", isPresented: $showSickSheet, titleVisibility: .visible) {
            Button("Yes, report sick & reassign route", role: .destructive) {
                driver.isSick = true
                driver.route.status = .notStarted
                withAnimation { showReassignBanner = true }
                voice.announce("Your route has been sent to dispatch for reassignment. Feel better soon.")
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your route will be sent to dispatch for reassignment.")
        }
        .sheet(isPresented: $showChat) {
            DriverDispatchChatView(
                driverID: driver.id,
                driverName: driver.name,
                viewerRole: .driver
            )
        }
    }

    // MARK: - Auto Detection
    private func runAutoDetection() async {
        while !driver.isSick && driver.route.status != .completed {
            try? await Task.sleep(nanoseconds: 10_000_000_000)
            guard case .inProgress = driver.route.status else { continue }
            let elapsed = Date().timeIntervalSince(lastActivityDate)
            if elapsed >= autoDelayThreshold && !dispatchNotified {
                driver.route.status = .delayed(reason: .busMaintenance)
                autoAlert = .autoDelayed
                dispatchNotified = true
                voice.announce("Alert. Bus has been stationary for 10 minutes. Delay has been reported to dispatch.")
            } else if elapsed >= autoPauseThreshold && autoAlert == nil {
                autoAlert = .autoPaused
                voice.announce("Alert. Bus appears stationary. Route has been paused.")
            }
        }
    }

    // MARK: - Stop Actions
    private func markCurrentStopComplete() {
        let idx = driver.route.currentStopIndex
        guard idx < driver.route.stops.count else { return }
        driver.route.stops[idx].isCompleted = true
        for i in driver.route.stops[idx].students.indices {
            if !driver.route.stops[idx].students[i].isAbsentToday {
                driver.route.stops[idx].students[i].isPickedUp = true
            }
        }
        if idx + 1 < driver.route.stops.count {
            driver.route.currentStopIndex = idx + 1
            let next = driver.route.stops[idx + 1]
            let count = next.boardingCount
            voice.announce("Stop complete. Heading to \(next.name). \(count) student\(count == 1 ? "" : "s") waiting.")
        } else {
            driver.route.status = .completed
            voice.announce("Route complete! All students have been delivered. Great job!")
        }
        lastActivityDate = Date()
        autoAlert = nil
        dispatchNotified = false
    }

    private func pickUpStudent(stopIdx: Int, studentId: UUID) {
        guard stopIdx < driver.route.stops.count else { return }
        if let si = driver.route.stops[stopIdx].students.firstIndex(where: { $0.id == studentId }) {
            let name = driver.route.stops[stopIdx].students[si].name.components(separatedBy: " ").first ?? ""
            driver.route.stops[stopIdx].students[si].isPickedUp = true
            voice.announce("\(name) is on board.")
            lastActivityDate = Date()
            autoAlert = nil
        }
    }

    // MARK: - Header
    private var driverHeader: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "1C3D6B"), driver.avatarColor],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea(edges: .top)

            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(10)
                            .background(Circle().fill(.white.opacity(0.15)))
                    }
                    Spacer()
                    // Chat button
                    Button { showChat = true } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "message.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                                .padding(10)
                                .background(Circle().fill(.white.opacity(0.15)))
                            let unread = chatStore.unreadCount(for: driver.id, as: .driver)
                            if unread > 0 {
                                Circle()
                                    .fill(Color(hex: "E74C3C"))
                                    .frame(width: 10, height: 10)
                                    .offset(x: 2, y: -2)
                            }
                        }
                    }
                    // Driving Mode button
                    if isRouteActive {
                        Button {
                            showDrivingMode = true
                        } label: {
                            Label("Drive Mode", systemImage: "car.fill")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Capsule().fill(.white.opacity(0.2)))
                        }
                    }
                    if !driver.isSick {
                        Button(action: { showSickSheet = true }) {
                            Label("Sick", systemImage: "thermometer.medium")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Capsule().fill(Color(hex: "E74C3C").opacity(0.75)))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)

                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(.white.opacity(0.2)).frame(width: 60, height: 60)
                        Text(String(driver.name.components(separatedBy: " ").last?.prefix(1) ?? "D"))
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(driver.name)
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        Text("Bus #\(driver.busNumber)  ·  \(driver.routeName)")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.75))
                    }
                    Spacer()
                    HStack(spacing: 5) {
                        Image(systemName: driver.route.status.icon)
                        Text(driver.route.status == .completed ? "Done" :
                             driver.route.status == .notStarted ? "Ready" : "Live")
                    }
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(.white.opacity(0.2)))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .frame(height: 170)
    }

    // MARK: - Auto Alert Banner
    private func autoAlertBanner(_ alert: AutoAlert) -> some View {
        HStack(spacing: 12) {
            Image(systemName: alert.icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(alert.color)
            VStack(alignment: .leading, spacing: 2) {
                Text(alert.title)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(hex: "1A1A2E"))
                Text(alert.subtitle)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(action: {
                autoAlert = nil
                dispatchNotified = false
                lastActivityDate = Date()
                if isRouteDelayed { driver.route.status = .inProgress }
            }) {
                Text("Dismiss")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(alert.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(alert.color.opacity(0.12)))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(alert.color.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(alert.color.opacity(0.3), lineWidth: 1))
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Reassign Banner
    private var reassignBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(hex: "2F80ED"))
            VStack(alignment: .leading, spacing: 2) {
                Text("Route sent to dispatch")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(hex: "1A1A2E"))
                Text("Dispatch is assigning a replacement driver")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: "2F80ED").opacity(0.07))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color(hex: "2F80ED").opacity(0.25), lineWidth: 1))
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Route Controls
    private var routeControlsCard: some View {
        VStack(spacing: 12) {
            Text("ROUTE CONTROLS")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
                .tracking(1.5)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 10) {
                if driver.route.status == .notStarted || isRoutePaused {
                    ControlButton(
                        label: driver.route.status == .notStarted ? "Start Route" : "Resume",
                        icon:  driver.route.status == .notStarted ? "play.fill" : "arrow.counterclockwise",
                        color: Color(hex: "2ECC71")
                    ) {
                        driver.route.status = .inProgress
                        if driver.route.startedAt == nil { driver.route.startedAt = Date() }
                        lastActivityDate = Date()
                        autoAlert = nil
                        showDrivingMode = true
                        let stop = driver.route.currentStop
                        let count = stop?.boardingCount ?? 0
                        voice.announce("Route started. First stop: \(stop?.name ?? "first stop"). \(count) student\(count == 1 ? "" : "s") waiting.")
                    }
                }
                if case .inProgress = driver.route.status {
                    ControlButton(label: "Pause", icon: "pause.fill", color: Color(hex: "F5A623")) {
                        showPauseSheet = true
                    }
                }
                if isRouteDelayed {
                    ControlButton(label: "Resume", icon: "arrow.counterclockwise", color: Color(hex: "2ECC71")) {
                        driver.route.status = .inProgress
                        lastActivityDate = Date()
                        autoAlert = nil
                        dispatchNotified = false
                        showDrivingMode = true
                        voice.announce("Delay cleared. Route resumed.")
                    }
                }
                if case .inProgress = driver.route.status {
                    ControlButton(label: "Report", icon: "exclamationmark.triangle.fill", color: Color(hex: "E74C3C")) {
                        showDelaySheet = true
                    }
                }
            }

            HStack(spacing: 6) {
                Image(systemName: driver.route.status.icon)
                Text(driver.route.status.label)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .foregroundColor(driver.route.status.color)
        }
        .padding(18)
        .background(cardBackground)
        .padding(.horizontal, 20)
    }

    // MARK: - Stats Grid
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(value: "\(driver.route.completedStops)/\(driver.route.totalStops)",
                     label: "Stops Done",    icon: "mappin.circle.fill",      color: Color(hex: "2F80ED"))
            StatCard(value: "\(driver.route.pickedUpStudents)/\(driver.route.totalStudents)",
                     label: "Picked Up",     icon: "person.2.fill",            color: Color(hex: "2ECC71"))
            StatCard(value: "\(driver.route.remainingStops)",
                     label: "Stops Left",    icon: "arrow.right.circle.fill",  color: Color(hex: "F5A623"))
            StatCard(value: "\(driver.route.totalStudents - driver.route.pickedUpStudents)",
                     label: "Still Waiting", icon: "clock.fill",               color: Color(hex: "9B59B6"))
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Progress Card
    private var progressCard: some View {
        VStack(spacing: 14) {
            ProgressRow(label: "Stops",
                        current: driver.route.completedStops,
                        total: driver.route.totalStops,
                        color: Color(hex: "2F80ED"))
            Divider()
            ProgressRow(label: "Students Aboard",
                        current: driver.route.pickedUpStudents,
                        total: driver.route.totalStudents,
                        color: Color(hex: "2ECC71"))
        }
        .padding(18)
        .background(cardBackground)
        .padding(.horizontal, 20)
    }

    // MARK: - Route Map Card
    private var driverRouteMapCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label {
                    Text("MY ROUTE")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "2F80ED"))
                        .tracking(1.5)
                } icon: {
                    Image(systemName: "map.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "2F80ED"))
                }
                Spacer()
                Text("\(driver.route.remainingStops) stops left")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            DriverLiveMapView(driver: driver)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(18)
        .background(cardBackground)
        .padding(.horizontal, 20)
    }

    // MARK: - Current Stop Card
    private var currentStopCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label {
                    Text("CURRENT STOP")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "2ECC71"))
                        .tracking(1.5)
                } icon: {
                    Image(systemName: "location.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "2ECC71"))
                }
                Spacer()
                if driver.route.currentStopIndex < driver.route.stops.count {
                    Text(driver.route.stops[driver.route.currentStopIndex].estimatedArrival)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            let idx = driver.route.currentStopIndex
            if idx < driver.route.stops.count {
                StopCard(
                    stop: $driver.route.stops[idx],
                    isCurrent: true,
                    onMarkComplete: { markCurrentStopComplete() },
                    onPickUp: { studentId in pickUpStudent(stopIdx: idx, studentId: studentId) }
                )
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color(hex: "2ECC71").opacity(0.35), lineWidth: 1.5))
                .shadow(color: Color(hex: "2ECC71").opacity(0.12), radius: 12, y: 4)
        )
        .padding(.horizontal, 20)
    }

    // MARK: - All Stops Card
    private var allStopsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ALL STOPS")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
                .tracking(1.5)
                .padding(.horizontal, 18)
                .padding(.top, 18)

            ForEach(Array(driver.route.stops.enumerated()), id: \.element.id) { idx, _ in
                let isCurr = idx == driver.route.currentStopIndex && isRouteActive
                StopCard(
                    stop: $driver.route.stops[idx],
                    isCurrent: isCurr,
                    onMarkComplete: {},
                    onPickUp: { studentId in pickUpStudent(stopIdx: idx, studentId: studentId) }
                )
                .padding(.horizontal, 14)

                if idx < driver.route.stops.count - 1 {
                    Rectangle()
                        .fill(Color.gray.opacity(0.12))
                        .frame(width: 1, height: 14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 48)
                }
            }
            .padding(.bottom, 14)
        }
        .background(cardBackground)
        .padding(.horizontal, 20)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white)
            .shadow(color: .black.opacity(0.07), radius: 10, y: 4)
    }
}

// MARK: - Safe Array Subscript
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Driving Mode View
struct DrivingModeView: View {
    @Binding var driver: Driver
    @ObservedObject var voice: VoiceAnnouncer
    let onDismiss: () -> Void

    @State private var showAtStop = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "0A1628"), Color(hex: "1A2E4A")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                drivingTopBar
                Spacer()
                nextStopInfo
                Spacer()
                atStopButton
                Button("View Full Dashboard") { onDismiss() }
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.35))
                    .padding(.top, 14)
                    .padding(.bottom, 44)
            }
        }
        .sheet(isPresented: $showAtStop) {
            AtStopSheet(driver: $driver, voice: voice) {
                showAtStop = false
                if driver.route.status == .completed { onDismiss() }
            }
        }
        .onAppear {
            if let stop = driver.route.currentStop {
                let count = stop.boardingCount
                voice.announce("Driving mode active. Next stop: \(stop.name). \(count) student\(count == 1 ? "" : "s") waiting.")
            }
        }
    }

    // MARK: Top Bar
    private var drivingTopBar: some View {
        HStack {
            HStack(spacing: 6) {
                Circle()
                    .fill(driver.route.status.color)
                    .frame(width: 8, height: 8)
                Text(driver.route.status.label)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(driver.route.status.color)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(.white.opacity(0.1)))

            Spacer()

            Text("Stop \(driver.route.currentStopIndex + 1) of \(driver.route.totalStops)")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.4))

            Spacer()

            Button {
                voice.isMuted.toggle()
            } label: {
                Image(systemName: voice.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 16))
                    .foregroundColor(voice.isMuted ? Color(hex: "E74C3C") : .white.opacity(0.7))
                    .padding(10)
                    .background(Circle().fill(.white.opacity(0.1)))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
    }

    // MARK: Next Stop Info
    private var nextStopInfo: some View {
        VStack(spacing: 20) {
            Text("NEXT STOP")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.4))
                .tracking(3)

            Text(driver.route.currentStop?.name ?? "—")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(driver.route.currentStop?.boardingCount ?? 0)")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(hex: "2ECC71"))
                    Text("Students\nWaiting")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }

                Rectangle()
                    .fill(.white.opacity(0.15))
                    .frame(width: 1, height: 60)

                VStack(spacing: 4) {
                    Text(driver.route.currentStop?.estimatedArrival ?? "--")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(hex: "F5A623"))
                    Text("Estimated\nArrival")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(24)
            .background(RoundedRectangle(cornerRadius: 20).fill(.white.opacity(0.07)))
            .padding(.horizontal, 32)

            VStack(spacing: 6) {
                let fraction = driver.route.totalStops > 0
                    ? Double(driver.route.completedStops) / Double(driver.route.totalStops)
                    : 0.0
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4).fill(.white.opacity(0.1)).frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "2ECC71"))
                            .frame(width: geo.size.width * fraction, height: 6)
                    }
                }
                .frame(height: 6)

                HStack {
                    Text("\(driver.route.completedStops) done")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                    Spacer()
                    Text("\(driver.route.remainingStops) remaining")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(.horizontal, 32)
        }
    }

    // MARK: AT STOP Button
    private var atStopButton: some View {
        Button { showAtStop = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 24))
                Text("AT STOP")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 76)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(hex: "2ECC71"))
                    .shadow(color: Color(hex: "2ECC71").opacity(0.45), radius: 18, y: 8)
            )
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - At Stop Sheet
struct AtStopSheet: View {
    @Binding var driver: Driver
    @ObservedObject var voice: VoiceAnnouncer
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss

    private var stopIdx: Int { driver.route.currentStopIndex }
    private var currentStop: RouteStop? {
        guard stopIdx < driver.route.stops.count else { return nil }
        return driver.route.stops[stopIdx]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let stop = currentStop {
                    VStack(spacing: 6) {
                        Text(stop.name)
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(hex: "1A1A2E"))
                            .multilineTextAlignment(.center)
                        Text(stop.estimatedArrival)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 16)
                }

                Divider()

                ScrollView {
                    VStack(spacing: 12) {
                        if currentStop != nil {
                            ForEach(driver.route.stops[stopIdx].students.indices, id: \.self) { si in
                                AtStopStudentRow(
                                    student: $driver.route.stops[stopIdx].students[si]
                                ) {
                                    driver.route.stops[stopIdx].students[si].isPickedUp = true
                                    let name = driver.route.stops[stopIdx].students[si].name
                                        .components(separatedBy: " ").first ?? ""
                                    voice.announce("\(name) is on board.")
                                }
                            }
                        }
                    }
                    .padding(20)
                }

                Button { completeStop() } label: {
                    Label("Complete Stop & Continue", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: "2ECC71"))
                                .shadow(color: Color(hex: "2ECC71").opacity(0.3), radius: 10, y: 4)
                        )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                .padding(.top, 12)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("STUDENTS AT THIS STOP")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            if let stop = currentStop {
                let count = stop.boardingCount
                let absent = stop.students.filter { $0.isAbsentToday }.count
                var msg = "At stop. \(stop.name). \(count) student\(count == 1 ? "" : "s") waiting."
                if absent > 0 { msg += " \(absent) absent today." }
                voice.announce(msg)
            }
        }
    }

    private func completeStop() {
        let idx = stopIdx
        guard idx < driver.route.stops.count else { return }
        driver.route.stops[idx].isCompleted = true
        for i in driver.route.stops[idx].students.indices {
            if !driver.route.stops[idx].students[i].isAbsentToday {
                driver.route.stops[idx].students[i].isPickedUp = true
            }
        }
        if idx + 1 < driver.route.stops.count {
            driver.route.currentStopIndex = idx + 1
            let next = driver.route.stops[idx + 1]
            let count = next.boardingCount
            voice.announce("Stop complete. Heading to \(next.name). \(count) student\(count == 1 ? "" : "s") waiting.")
        } else {
            driver.route.status = .completed
            voice.announce("Route complete! All students have been delivered. Great job!")
        }
        dismiss()
        onComplete()
    }
}

// MARK: - At Stop Student Row
struct AtStopStudentRow: View {
    @Binding var student: RouteStudent
    let onPickUp: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(rowColor.opacity(0.15))
                    .frame(width: 50, height: 50)
                Text(String(student.name.prefix(1)))
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(rowColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(student.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(student.isAbsentToday ? .secondary : Color(hex: "1A1A2E"))
                    .strikethrough(student.isAbsentToday)
                Text(student.grade)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if student.isAbsentToday {
                Text("ABSENT")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(Color(hex: "E74C3C"))
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "E74C3C").opacity(0.1)))
            } else if student.isPickedUp {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("ABOARD")
                }
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundColor(Color(hex: "2ECC71"))
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "2ECC71").opacity(0.1)))
            } else {
                Button(action: onPickUp) {
                    Text("PICK UP")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20).padding(.vertical, 13)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(hex: "F5A623"))
                                .shadow(color: Color(hex: "F5A623").opacity(0.35), radius: 6, y: 3)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(student.isPickedUp ? Color(hex: "2ECC71").opacity(0.05) : .white)
                .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        )
    }

    private var rowColor: Color {
        if student.isAbsentToday { return Color(hex: "E74C3C") }
        if student.isPickedUp    { return Color(hex: "2ECC71") }
        return Color(hex: "F5A623")
    }
}

// MARK: - Stop Card
struct StopCard: View {
    @Binding var stop: RouteStop
    let isCurrent: Bool
    let onMarkComplete: () -> Void
    let onPickUp: (UUID) -> Void
    @State private var expanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button(action: { withAnimation(.spring(response: 0.3)) { expanded.toggle() } }) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(stopColor.opacity(0.15)).frame(width: 36, height: 36)
                        Image(systemName: stopIcon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(stopColor)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(stop.name)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "1A1A2E"))
                            .multilineTextAlignment(.leading)
                        HStack(spacing: 6) {
                            Text(stop.estimatedArrival)
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(.secondary)
                            if stop.students.contains(where: { $0.isAbsentToday }) {
                                Text("· \(stop.students.filter { $0.isAbsentToday }.count) absent")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundColor(Color(hex: "E74C3C"))
                            }
                        }
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text("\(stop.pickedUpCount)/\(stop.boardingCount)")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundColor(stopColor)
                        Text("students")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(spacing: 0) {
                    Divider().padding(.vertical, 4)
                    VStack(spacing: 6) {
                        ForEach(stop.students.indices, id: \.self) { si in
                            StudentRow(student: $stop.students[si]) {
                                onPickUp(stop.students[si].id)
                            }
                        }
                    }
                    if isCurrent && !stop.isCompleted {
                        Button(action: onMarkComplete) {
                            Label("Mark Stop Complete", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: "2ECC71"))
                                        .shadow(color: Color(hex: "2ECC71").opacity(0.3), radius: 6, y: 3)
                                )
                        }
                        .padding(.top, 8)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var stopColor: Color {
        if stop.isCompleted { return Color(hex: "2ECC71") }
        if isCurrent        { return Color(hex: "F5A623") }
        return .secondary
    }
    private var stopIcon: String {
        if stop.isCompleted { return "checkmark.circle.fill" }
        if isCurrent        { return "location.fill" }
        return "circle"
    }
}

// MARK: - Student Row
struct StudentRow: View {
    @Binding var student: RouteStudent
    let onPickUp: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Circle().fill(rowColor).frame(width: 8, height: 8)
            ZStack {
                Circle().fill(rowColor.opacity(0.12)).frame(width: 28, height: 28)
                Text(String(student.name.prefix(1)))
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(rowColor)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(student.name)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(student.isAbsentToday ? .secondary : Color(hex: "1A1A2E"))
                    .strikethrough(student.isAbsentToday)
                Text(student.grade)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.secondary)
            }
            Spacer()
            if student.isAbsentToday {
                Text("Absent")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "E74C3C"))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(Color(hex: "E74C3C").opacity(0.1)))
            } else if student.isPickedUp {
                Label("Aboard", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "2ECC71"))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(Color(hex: "2ECC71").opacity(0.1)))
            } else {
                Button(action: onPickUp) {
                    Text("Pick Up")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "F5A623"))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(
                            Capsule().fill(Color(hex: "F5A623").opacity(0.1))
                                .overlay(Capsule().strokeBorder(Color(hex: "F5A623").opacity(0.3), lineWidth: 1))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 5)
    }

    private var rowColor: Color {
        if student.isAbsentToday { return Color(hex: "E74C3C") }
        if student.isPickedUp    { return Color(hex: "2ECC71") }
        return Color(hex: "F5A623")
    }
}

// MARK: - Control Button
struct ControlButton: View {
    let label: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle().fill(color.opacity(0.12)).frame(width: 50, height: 50)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(color)
                }
                Text(label)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.1)).frame(width: 40, height: 40)
                Image(systemName: icon).font(.system(size: 16, weight: .semibold)).foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(hex: "1A1A2E"))
                Text(label)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(.white).shadow(color: .black.opacity(0.06), radius: 8, y: 3))
    }
}

// MARK: - Progress Row
struct ProgressRow: View {
    let label: String
    let current: Int
    let total: Int
    let color: Color

    private var fraction: Double { total > 0 ? Double(current) / Double(total) : 0 }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "1A1A2E"))
                Spacer()
                Text("\(current) of \(total)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6).fill(color.opacity(0.1)).frame(height: 10)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(colors: [color.opacity(0.7), color],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * fraction, height: 10)
                        .animation(.spring(response: 0.5), value: fraction)
                }
            }
            .frame(height: 10)
        }
    }
}

// MARK: - Auto Alert
enum AutoAlert {
    case autoPaused, autoDelayed

    var title: String {
        switch self {
        case .autoPaused:  return "Bus appears stationary (5 min)"
        case .autoDelayed: return "Auto-delayed — Dispatch notified!"
        }
    }
    var subtitle: String {
        switch self {
        case .autoPaused:  return "Route auto-paused. Tap Dismiss when moving again."
        case .autoDelayed: return "Bus has been in the same location for 10+ minutes."
        }
    }
    var icon: String {
        switch self {
        case .autoPaused:  return "pause.circle.fill"
        case .autoDelayed: return "exclamationmark.triangle.fill"
        }
    }
    var color: Color {
        switch self {
        case .autoPaused:  return Color(hex: "F5A623")
        case .autoDelayed: return Color(hex: "E74C3C")
        }
    }
}

// MARK: - Delay Report Sheet
struct DelayReportSheet: View {
    let onReport: (RouteStatus.DelayReason) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(RouteStatus.DelayReason.allCases, id: \.self) { reason in
                Button(action: { onReport(reason); dismiss() }) {
                    HStack {
                        Image(systemName: reasonIcon(reason))
                            .foregroundColor(Color(hex: "E74C3C"))
                            .frame(width: 28)
                        Text(reason.rawValue)
                            .font(.system(size: 15, design: .rounded))
                            .foregroundColor(Color(hex: "1A1A2E"))
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Report Delay")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
        .presentationDetents([.medium])
    }

    private func reasonIcon(_ r: RouteStatus.DelayReason) -> String {
        switch r {
        case .heavyTraffic:      return "car.fill"
        case .accident:          return "exclamationmark.triangle.fill"
        case .roadClosure:       return "xmark.octagon.fill"
        case .busMaintenance:    return "wrench.and.screwdriver.fill"
        case .medicalEmergency:  return "cross.fill"
        case .studentIncident:   return "person.crop.circle.badge.exclamationmark"
        case .weatherConditions: return "cloud.bolt.rain.fill"
        case .other:             return "ellipsis.circle.fill"
        }
    }
}

// MARK: - Pause Report Sheet
struct PauseReportSheet: View {
    let onPause: (RouteStatus.PauseReason) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(RouteStatus.PauseReason.allCases, id: \.self) { reason in
                Button(action: { onPause(reason); dismiss() }) {
                    HStack {
                        Image(systemName: "pause.circle.fill")
                            .foregroundColor(Color(hex: "F5A623"))
                            .frame(width: 28)
                        Text(reason.rawValue)
                            .font(.system(size: 15, design: .rounded))
                            .foregroundColor(Color(hex: "1A1A2E"))
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Pause Reason")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
        .presentationDetents([.fraction(0.4)])
    }
}

// MARK: - Driver Live Map View
struct DriverLiveMapView: View {
    let driver: Driver
    @State private var position: MapCameraPosition

    init(driver: Driver) {
        self.driver = driver
        let coords = driver.route.stops.map { $0.coordinate }
        let lats = coords.map { $0.latitude }
        let lons = coords.map { $0.longitude }
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else {
            _position = State(initialValue: .automatic)
            return
        }
        let center = CLLocationCoordinate2D(
            latitude:  (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta:  max(maxLat - minLat, 0.005) * 1.6,
            longitudeDelta: max(maxLon - minLon, 0.005) * 1.6
        )
        _position = State(initialValue: .region(MKCoordinateRegion(center: center, span: span)))
    }

    private var completedCoords: [CLLocationCoordinate2D] {
        Array(driver.route.stops.prefix(driver.route.currentStopIndex + 1)).map { $0.coordinate }
    }
    private var remainingCoords: [CLLocationCoordinate2D] {
        Array(driver.route.stops.suffix(from: max(0, driver.route.currentStopIndex))).map { $0.coordinate }
    }

    var body: some View {
        Map(position: $position) {
            if completedCoords.count > 1 {
                MapPolyline(coordinates: completedCoords)
                    .stroke(Color(hex: "2ECC71"), style: StrokeStyle(lineWidth: 4, lineCap: .round))
            }
            if remainingCoords.count > 1 {
                MapPolyline(coordinates: remainingCoords)
                    .stroke(Color(hex: "2F80ED"), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [6, 4]))
            }
            ForEach(Array(driver.route.stops.enumerated()), id: \.element.id) { idx, stop in
                Annotation(stop.name, coordinate: stop.coordinate) {
                    ZStack {
                        Circle()
                            .fill(stop.isCompleted
                                  ? Color(hex: "2ECC71")
                                  : idx == driver.route.currentStopIndex
                                    ? Color(hex: "F5A623") : .white)
                            .frame(width: 24, height: 24)
                            .shadow(color: .black.opacity(0.15), radius: 3)
                            .overlay(Circle().strokeBorder(
                                stop.isCompleted ? Color(hex: "2ECC71") : Color(hex: "2F80ED"),
                                lineWidth: 1.5
                            ))
                        if stop.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold)).foregroundColor(.white)
                        } else {
                            Text("\(idx + 1)")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(idx == driver.route.currentStopIndex ? .white : Color(hex: "2F80ED"))
                        }
                    }
                }
            }
            if let current = driver.route.currentStop {
                Annotation("Bus \(driver.busNumber)", coordinate: current.coordinate) {
                    ZStack {
                        Circle()
                            .fill(driver.route.status.color)
                            .frame(width: 42, height: 42)
                            .shadow(color: driver.route.status.color.opacity(0.5), radius: 8)
                        Image(systemName: "bus.fill")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }
}

#Preview { DriverDashboardView(driver: .constant(Driver.sampleDrivers[0])) }
