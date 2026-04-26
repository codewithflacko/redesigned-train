import SwiftUI
import MapKit
import PhotosUI

// MARK: - Parent Dashboard
struct ParentDashboardView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var auth = AuthManager.shared
    @State private var showNotifications = false
    @State private var showInviteSheet = false
    @State private var notifications = ParentNotification.samples
    @Environment(\.dismiss) private var dismiss

    private var unreadCount: Int { notifications.filter { !$0.isRead }.count }

    private var arrivedCount: Int { appState.children.filter { $0.busTracking.hasArrivedAtSchool }.count }
    private var enRouteCount: Int { appState.children.filter { !$0.busTracking.hasArrivedAtSchool && !$0.isAbsentToday }.count }

    var body: some View {
        ZStack {
            Color(hex: "F2F6FA").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    dashboardHeader

                    // Summary strip
                    summaryStrip

                    // Child cards
                    ForEach(appState.children.indices, id: \.self) { idx in
                        ChildTrackerCard(child: $appState.children[idx])
                            .padding(.horizontal, 20)
                    }

                    Spacer().frame(height: 20)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showNotifications) {
            NotificationCenterView(notifications: $notifications)
        }
        .sheet(isPresented: $showInviteSheet) {
            InviteParentView()
        }
    }

    // MARK: - Header
    private var dashboardHeader: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "1C3D6B"), Color(hex: "2F6BAD")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea(edges: .top)

            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(.white.opacity(0.85))
                    }
                    Spacer()
                    HStack(spacing: 14) {
                        if auth.accessLevel == "full" {
                            Button(action: { showInviteSheet = true }) {
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                        }
                        Button(action: { showNotifications.toggle() }) {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                                if unreadCount > 0 {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: "E74C3C"))
                                            .frame(width: unreadCount > 9 ? 16 : 10,
                                                   height: unreadCount > 9 ? 16 : 10)
                                        if unreadCount > 1 {
                                            Text("\(min(unreadCount, 9))\(unreadCount > 9 ? "+" : "")")
                                                .font(.system(size: 7, weight: .black))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .offset(x: 4, y: -4)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 56)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Good Morning,")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.75))
                        Text("Sarah Johnson")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        Text(Date().formatted(date: .complete, time: .omitted))
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
        }
        .frame(height: 170)
    }

    // MARK: - Summary Strip
    private var summaryStrip: some View {
        HStack(spacing: 12) {
            SummaryPill(
                value: "\(appState.children.count)",
                label: "Children",
                icon: "person.2.fill",
                color: Color(hex: "2F6BAD")
            )
            SummaryPill(
                value: "\(enRouteCount)",
                label: "En Route",
                icon: "bus.fill",
                color: Color(hex: "F5A623")
            )
            SummaryPill(
                value: "\(arrivedCount)",
                label: "Arrived",
                icon: "checkmark.seal.fill",
                color: Color(hex: "2ECC71")
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, -10)
    }
}

// MARK: - Summary Pill
struct SummaryPill: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(hex: "1A1A2E"))
                Text(label)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.white)
                .shadow(color: .black.opacity(0.07), radius: 6, y: 3)
        )
    }
}

// MARK: - Child Tracker Card
struct ChildTrackerCard: View {
    @Binding var child: Child
    @ObservedObject private var auth = AuthManager.shared
    @State private var showAbsenceSheet = false
    @State private var isPulsing = false
    @State private var mapExpanded = false

    private var isNearby: Bool {
        guard let stops = child.busTracking.stopsAway else { return false }
        return stops <= 3 && !child.busTracking.hasArrivedAtSchool && !child.isAbsentToday
    }

    var body: some View {
        VStack(spacing: 0) {
            // Card header
            cardHeader

            // Proximity alert banner
            if isNearby, let stops = child.busTracking.stopsAway {
                proximityBanner(stopsAway: stops)
            }

            // Arrived banner
            if child.busTracking.hasArrivedAtSchool {
                arrivedBanner
            }

            // Absent overlay content
            if child.isAbsentToday {
                absentNotice
            } else {
                // Map + details
                VStack(spacing: 14) {
                    BusMapView(
                        tracking: child.busTracking,
                        isExpanded: $mapExpanded
                    )

                    statusRow

                    if auth.accessLevel == "full" {
                        absenceButton
                    } else {
                        viewOnlyBadge
                    }
                }
                .padding(16)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(child.isAbsentToday ? Color.gray.opacity(0.08) : Color.white)
                .shadow(
                    color: isNearby ? Color(hex: "F5A623").opacity(0.25) : .black.opacity(0.08),
                    radius: isNearby ? 16 : 12,
                    y: 4
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(
                    isNearby ? Color(hex: "F5A623").opacity(0.5) : Color.clear,
                    lineWidth: 1.5
                )
        )
        .animation(.easeInOut(duration: 0.3), value: child.isAbsentToday)
        .confirmationDialog(
            "Mark \(child.name) as Absent",
            isPresented: $showAbsenceSheet,
            titleVisibility: .visible
        ) {
            Button("Mark as Absent Today", role: .destructive) {
                AppState.shared.setChildAbsent(child.id, absent: true)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The driver will be notified and will skip this stop if no other children are boarding.")
        }
    }

    // MARK: - Card Header
    private var cardHeader: some View {
        HStack(spacing: 12) {
            ChildAvatarView(child: $child)

            VStack(alignment: .leading, spacing: 2) {
                Text(child.name)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "1A1A2E"))
                Text("\(child.grade)  •  Bus #\(child.busTracking.busNumber)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Status badge
            HStack(spacing: 5) {
                Circle()
                    .fill(child.busTracking.status.color)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isPulsing && isNearby ? 1.3 : 1.0)
                    .animation(
                        isNearby ? .easeInOut(duration: 0.7).repeatForever(autoreverses: true) : .default,
                        value: isPulsing
                    )
                Text(child.isAbsentToday ? "Absent" : child.busTracking.status.label)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(child.isAbsentToday ? .secondary : child.busTracking.status.color)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill((child.isAbsentToday ? Color.gray : child.busTracking.status.color).opacity(0.1))
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .onAppear { isPulsing = true }
    }

    // MARK: - Proximity Banner
    private func proximityBanner(stopsAway: Int) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "bus.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(stopsAway == 1 ? Color(hex: "E74C3C") : Color(hex: "E67E22"))
                .scaleEffect(isPulsing ? 1.1 : 0.95)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isPulsing)

            VStack(alignment: .leading, spacing: 1) {
                Text(stopsAway == 1 ? "Bus is next — Get outside now!" : "Bus is \(stopsAway) stops away!")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(hex: "1A1A2E"))
                if let eta = child.busTracking.estimatedArrival {
                    Text("ETA \(eta)  •  Get \(child.name) ready!")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [
                    Color(hex: stopsAway == 1 ? "FFF0F0" : "FFF8E7"),
                    Color(hex: stopsAway == 1 ? "FFE5E5" : "FFF3CC")
                ],
                startPoint: .leading, endPoint: .trailing
            )
        )
    }

    // MARK: - Arrived Banner
    private var arrivedBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "2ECC71"))
            VStack(alignment: .leading, spacing: 1) {
                Text("\(child.name) has arrived at school!")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(hex: "1A1A2E"))
                Text(child.busTracking.schoolName)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: "F0FBF4"))
        .padding(.bottom, 4)
    }

    // MARK: - Status Row
    private var statusRow: some View {
        HStack {
            Label {
                Text(child.busTracking.status.label)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "1A1A2E"))
            } icon: {
                Image(systemName: child.busTracking.status.icon)
                    .foregroundColor(child.busTracking.status.color)
            }

            Spacer()

            if let eta = child.busTracking.estimatedArrival,
               !child.busTracking.hasArrivedAtSchool {
                Label {
                    Text("ETA \(eta)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                } icon: {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                }
            }

            Label {
                Text(child.busTracking.driverName)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            } icon: {
                Image(systemName: "steeringwheel")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Absence Button
    private var absenceButton: some View {
        Button(action: { showAbsenceSheet = true }) {
            HStack(spacing: 8) {
                Image(systemName: "person.crop.circle.badge.xmark")
                    .font(.system(size: 15, weight: .semibold))
                Text("Report \(child.name) Absent Today")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundColor(Color(hex: "E74C3C"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "E74C3C").opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color(hex: "E74C3C").opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - View-Only Badge
    private var viewOnlyBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.system(size: 13, weight: .semibold))
            Text("View Only — contact the primary parent to report absences")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .multilineTextAlignment(.center)
        }
        .foregroundColor(.secondary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.gray.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Absent Notice
    private var absentNotice: some View {
        VStack(spacing: 10) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 28))
                .foregroundColor(.secondary)
            Text("\(child.name) is marked absent today")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
            Text("Driver has been notified")
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(Color.secondary.opacity(0.7))

            Button(action: { AppState.shared.setChildAbsent(child.id, absent: false) }) {
                Text("Undo — Mark as Present")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "2ECC71"))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color(hex: "2ECC71").opacity(0.1))
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
    }
}

// MARK: - Live Bus Map View
struct BusMapView: View {
    let tracking: BusTracking
    @Binding var isExpanded: Bool

    // Live state
    @State private var liveBusPosition: CLLocationCoordinate2D
    @State private var cameraPosition: MapCameraPosition
    @State private var waypointIndex: Int
    @State private var followBus = true
    @State private var liveDot = false

    // Full route: bus origin → child's stop → school (50 steps per segment)
    private let waypoints: [CLLocationCoordinate2D]

    init(tracking: BusTracking, isExpanded: Binding<Bool>) {
        self.tracking = tracking
        self._isExpanded = isExpanded

        // Build interpolated waypoints
        let steps = 120
        var pts: [CLLocationCoordinate2D] = []
        for (from, to) in [(tracking.busCoordinate, tracking.stopCoordinate),
                           (tracking.stopCoordinate, tracking.schoolCoordinate)] {
            for i in 0..<steps {
                let t = Double(i) / Double(steps)
                pts.append(CLLocationCoordinate2D(
                    latitude:  from.latitude  + (to.latitude  - from.latitude)  * t,
                    longitude: from.longitude + (to.longitude - from.longitude) * t
                ))
            }
        }
        pts.append(tracking.schoolCoordinate)
        self.waypoints = pts

        // If already arrived, start at the end
        let startIndex = tracking.hasArrivedAtSchool ? pts.count - 1 : 0
        self._waypointIndex = State(initialValue: startIndex)
        self._liveBusPosition = State(initialValue: tracking.hasArrivedAtSchool
            ? tracking.schoolCoordinate
            : tracking.busCoordinate)

        let initialRegion = MKCoordinateRegion(
            center: tracking.busCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
        )
        self._cameraPosition = State(initialValue: .region(initialRegion))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Map(position: $cameraPosition) {
                // Completed route segment (green trail)
                if waypointIndex > 1 {
                    MapPolyline(coordinates: Array(waypoints[0...waypointIndex]))
                        .stroke(Color(hex: "2ECC71").opacity(0.7), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                }

                // Remaining route segment (blue dashed)
                if waypointIndex < waypoints.count - 2 {
                    MapPolyline(coordinates: Array(waypoints[waypointIndex...]))
                        .stroke(Color(hex: "2F80ED").opacity(0.45), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [6, 5]))
                }

                // Live bus pin
                Annotation("Bus #\(tracking.busNumber)", coordinate: liveBusPosition) {
                    LiveBusPin(busNumber: tracking.busNumber)
                }

                // Child's pickup stop
                Annotation(tracking.stopName, coordinate: tracking.stopCoordinate) {
                    StopPin()
                }

                // School
                Annotation(tracking.schoolName, coordinate: tracking.schoolCoordinate) {
                    SchoolPin()
                }
            }
            .mapStyle(.standard)
            .frame(height: isExpanded ? 340 : 185)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(alignment: .topLeading) { liveLabel }

            // Controls
            VStack(spacing: 8) {
                // Follow bus toggle
                Button(action: { followBus.toggle() }) {
                    Image(systemName: followBus ? "location.fill" : "location")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(followBus ? Color(hex: "2F80ED") : .white)
                        .padding(9)
                        .background(Circle().fill(followBus ? .white : Color.black.opacity(0.5)))
                        .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
                }

                // Expand / collapse
                Button(action: { withAnimation(.spring(response: 0.4)) { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded
                          ? "arrow.down.right.and.arrow.up.left"
                          : "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(9)
                        .background(Circle().fill(Color.black.opacity(0.5)))
                }
            }
            .padding(10)

            // Legend
            HStack(spacing: 10) {
                MapLegendDot(color: Color(hex: "FFD100"), label: "Bus")
                MapLegendDot(color: Color(hex: "2F80ED"), label: "Stop")
                MapLegendDot(color: Color(hex: "E74C3C"), label: "School")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(.ultraThinMaterial))
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        // Animate bus along route
        .task {
            guard !tracking.hasArrivedAtSchool else { return }
            await animateBus()
        }
        // Camera follow — runs on main thread so withAnimation is reliable
        .onChange(of: liveBusPosition.latitude) { _, _ in
            guard followBus else { return }
            withAnimation(.linear(duration: 4.8)) {
                cameraPosition = .region(MKCoordinateRegion(
                    center: liveBusPosition,
                    span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
                ))
            }
        }
        // Pulse the LIVE dot
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                liveDot = true
            }
        }
    }

    // MARK: - LIVE badge
    private var liveLabel: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(Color(hex: "E74C3C"))
                .frame(width: 7, height: 7)
                .opacity(liveDot ? 1 : 0.3)
            Text("LIVE")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Capsule().fill(Color.black.opacity(0.55)))
        .padding(10)
    }

    // MARK: - Bus animation loop
    private func animateBus() async {
        while waypointIndex < waypoints.count - 1 {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            waypointIndex = min(waypointIndex + 1, waypoints.count - 1)
            liveBusPosition = waypoints[waypointIndex]
        }
        // Reached school — wait 2 minutes before looping (demo only)
        try? await Task.sleep(nanoseconds: 120_000_000_000)
        waypointIndex = 0
        liveBusPosition = waypoints[0]
        withAnimation(.easeInOut(duration: 1.5)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: waypoints[0],
                span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
            ))
        }
        await animateBus()
    }
}

// MARK: - Map Pins
struct LiveBusPin: View {
    let busNumber: String
    @State private var pulse = false

    var body: some View {
        ZStack {
            // Pulse ring
            Circle()
                .stroke(Color(hex: "FFD100").opacity(0.4), lineWidth: 3)
                .frame(width: pulse ? 58 : 46, height: pulse ? 58 : 46)
                .opacity(pulse ? 0 : 0.8)
                .animation(.easeOut(duration: 1.2).repeatForever(autoreverses: false), value: pulse)

            Circle()
                .fill(Color(hex: "FFD100"))
                .frame(width: 44, height: 44)
                .shadow(color: Color(hex: "FFD100").opacity(0.5), radius: 6, y: 2)

            Image(systemName: "bus.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(hex: "1A1A1A"))
        }
        .onAppear { pulse = true }
    }
}

struct StopPin: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "2F80ED"))
                .frame(width: 36, height: 36)
                .shadow(color: Color(hex: "2F80ED").opacity(0.45), radius: 5, y: 2)
            Image(systemName: "figure.stand")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

struct SchoolPin: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "E74C3C"))
                .frame(width: 36, height: 36)
                .shadow(color: Color(hex: "E74C3C").opacity(0.45), radius: 5, y: 2)
            Image(systemName: "building.columns.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

struct MapLegendDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Child Avatar View
struct ChildAvatarView: View {
    @Binding var child: Child
    @State private var selectedItem: PhotosPickerItem?
    @State private var showPicker = false

    var body: some View {
        PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
            ZStack(alignment: .bottomTrailing) {
                // Photo or colored initial
                Group {
                    if let data = child.photoData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        ZStack {
                            Circle().fill(child.avatarColor.opacity(0.15))
                            Text(String(child.name.prefix(1)))
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                                .foregroundColor(child.avatarColor)
                        }
                    }
                }
                .frame(width: 52, height: 52)
                .clipShape(Circle())
                .overlay(
                    Circle().strokeBorder(
                        child.photoData != nil ? child.avatarColor.opacity(0.5) : child.avatarColor.opacity(0.2),
                        lineWidth: 2
                    )
                )

                // Camera badge
                ZStack {
                    Circle()
                        .fill(child.avatarColor)
                        .frame(width: 18, height: 18)
                    Image(systemName: "camera.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(x: 2, y: 2)
            }
        }
        .onChange(of: selectedItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self) {
                    child.photoData = data
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ParentDashboardView()
        .environmentObject(AppState.shared)
}
