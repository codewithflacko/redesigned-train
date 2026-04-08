import SwiftUI

// MARK: - Driver Dashboard
struct DriverDashboardView: View {
    @State var driver: Driver
    @State private var showDelaySheet     = false
    @State private var showPauseSheet     = false
    @State private var showSickSheet      = false
    @State private var showReassignBanner = false
    @State private var autoAlert: AutoAlert? = nil
    @State private var lastActivityDate   = Date()
    @State private var dispatchNotified   = false
    @Environment(\.dismiss) private var dismiss

    // Demo timings — change to 300/600 for production (5 min / 10 min)
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
                    if isRouteActive { currentStopCard }
                    allStopsCard
                    Spacer().frame(height: 20)
                }
            }
        }
        .navigationBarHidden(true)
        .task { await runAutoDetection() }
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
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your route will be sent to dispatch for reassignment.")
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
            } else if elapsed >= autoPauseThreshold && autoAlert == nil {
                autoAlert = .autoPaused
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
        } else {
            driver.route.status = .completed
        }
        lastActivityDate = Date()
        autoAlert = nil
        dispatchNotified = false
    }

    private func pickUpStudent(stopIdx: Int, studentId: UUID) {
        guard stopIdx < driver.route.stops.count else { return }
        if let si = driver.route.stops[stopIdx].students.firstIndex(where: { $0.id == studentId }) {
            driver.route.stops[stopIdx].students[si].isPickedUp = true
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
                    if !driver.isSick {
                        Button(action: { showSickSheet = true }) {
                            Label("Report Sick", systemImage: "thermometer.medium")
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
        case .heavyTraffic:       return "car.fill"
        case .accident:           return "exclamationmark.triangle.fill"
        case .roadClosure:        return "xmark.octagon.fill"
        case .busMaintenance:     return "wrench.and.screwdriver.fill"
        case .medicalEmergency:   return "cross.fill"
        case .studentIncident:    return "person.crop.circle.badge.exclamationmark"
        case .weatherConditions:  return "cloud.bolt.rain.fill"
        case .other:              return "ellipsis.circle.fill"
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

#Preview { DriverDashboardView(driver: Driver.sampleDrivers[0]) }
