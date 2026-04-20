import SwiftUI
import MapKit

// MARK: - Dispatch Filter
enum DispatchFilter: String, CaseIterable {
    case all       = "All"
    case onTime    = "On Time"
    case delayed   = "Delayed"
    case paused    = "Paused"
    case arrived   = "Arrived"
    case reassign  = "Needs Reassign"

    var icon: String {
        switch self {
        case .all:      return "square.grid.2x2"
        case .onTime:   return "checkmark.circle"
        case .delayed:  return "exclamationmark.triangle"
        case .paused:   return "pause.circle"
        case .arrived:  return "building.columns"
        case .reassign: return "arrow.triangle.2.circlepath"
        }
    }

    var color: Color {
        switch self {
        case .all:      return Color(hex: "2F80ED")
        case .onTime:   return Color(hex: "2ECC71")
        case .delayed:  return Color(hex: "E74C3C")
        case .paused:   return Color(hex: "F5A623")
        case .arrived:  return Color(hex: "8E44AD")
        case .reassign: return Color(hex: "9B59B6")
        }
    }
}

// MARK: - Dispatch Dashboard
struct DispatchDashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedFilter: DispatchFilter = .all
    @State private var selectedDriver: Driver? = nil
    @Environment(\.dismiss) private var dismiss

    private var drivers: [Driver] { appState.drivers }

    // MARK: Computed counts
    private var sickDrivers:  [Driver] { drivers.filter { $0.isSick } }
    private var onTimeCount:  Int { drivers.filter { $0.route.status == .inProgress }.count }
    private var arrivedCount: Int { drivers.filter { $0.route.status == .completed  }.count }
    private var delayedCount: Int {
        drivers.filter { if case .delayed = $0.route.status { return true }; return false }.count
    }
    private var pausedCount: Int {
        drivers.filter { if case .paused = $0.route.status { return true }; return false }.count
    }

    private var filteredDrivers: [Driver] {
        switch selectedFilter {
        case .all:      return drivers
        case .onTime:   return drivers.filter { $0.route.status == .inProgress }
        case .delayed:  return drivers.filter { if case .delayed = $0.route.status { return true }; return false }
        case .paused:   return drivers.filter { if case .paused  = $0.route.status { return true }; return false }
        case .arrived:  return drivers.filter { $0.route.status == .completed }
        case .reassign: return drivers.filter { $0.isSick }
        }
    }

    private func countFor(_ filter: DispatchFilter) -> Int {
        switch filter {
        case .all:      return drivers.count
        case .onTime:   return onTimeCount
        case .delayed:  return delayedCount
        case .paused:   return pausedCount
        case .arrived:  return arrivedCount
        case .reassign: return sickDrivers.count
        }
    }

    // MARK: Body
    var body: some View {
        ZStack {
            Color(hex: "F0F4F8").ignoresSafeArea()
            VStack(spacing: 0) {
                headerBar
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Fleet overview map
                        DispatchOverviewMap(drivers: drivers) { driver in
                            selectedDriver = driver
                        }
                        .frame(height: 210)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal, 16)
                        .shadow(color: .black.opacity(0.12), radius: 10, y: 4)

                        summaryStrip

                        if !sickDrivers.isEmpty {
                            reassignBanner
                        }

                        filterRow

                        driverCards

                        Spacer().frame(height: 24)
                    }
                    .padding(.top, 16)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(item: $selectedDriver) { driver in
            DriverDetailSheet(driver: driver, allDrivers: $appState.drivers)
        }
    }

    // MARK: - Header
    private var headerBar: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "1A3A5C"), Color(hex: "2F80ED")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea(edges: .top)

            HStack {
                Button { dismiss() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.white.opacity(0.85))
                }

                Spacer()

                VStack(spacing: 2) {
                    Text("Dispatch Center")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text("\(drivers.count) buses monitored")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                // Live badge
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color(hex: "2ECC71"))
                        .frame(width: 8, height: 8)
                    Text("LIVE")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .frame(height: 60)
    }

    // MARK: - Summary Strip
    private var summaryStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                DispatchStatPill(value: drivers.count,    label: "Total",   color: Color(hex: "2F80ED"))
                DispatchStatPill(value: onTimeCount,      label: "On Time", color: Color(hex: "2ECC71"))
                DispatchStatPill(value: delayedCount,     label: "Delayed", color: Color(hex: "E74C3C"))
                DispatchStatPill(value: pausedCount,      label: "Paused",  color: Color(hex: "F5A623"))
                DispatchStatPill(value: arrivedCount,     label: "Arrived", color: Color(hex: "8E44AD"))
                DispatchStatPill(value: sickDrivers.count, label: "Sick",   color: Color(hex: "95A5A6"))
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Reassign Banner
    private var reassignBanner: some View {
        VStack(spacing: 8) {
            ForEach(sickDrivers) { sick in
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 16))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(sick.name) has reported sick")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Bus #\(sick.busNumber) · \(sick.routeName) needs reassignment")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                    }

                    Spacer()

                    Button {
                        selectedDriver = sick
                    } label: {
                        Text("Assign")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "9B59B6"))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(RoundedRectangle(cornerRadius: 10).fill(.white))
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: "9B59B6"))
                        .shadow(color: Color(hex: "9B59B6").opacity(0.3), radius: 8, y: 3)
                )
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Filter Row
    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DispatchFilter.allCases, id: \.self) { filter in
                    let count = countFor(filter)
                    let isSelected = selectedFilter == filter

                    Button {
                        withAnimation(.spring(response: 0.3)) { selectedFilter = filter }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: filter.icon)
                                .font(.system(size: 11, weight: .semibold))
                            Text(filter.rawValue)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                            if count > 0 {
                                Text("\(count)")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(Capsule().fill(isSelected ? .white.opacity(0.3) : filter.color.opacity(0.15)))
                            }
                        }
                        .foregroundColor(isSelected ? .white : filter.color)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(
                            Capsule().fill(isSelected ? filter.color : filter.color.opacity(0.1))
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Driver Cards
    private var driverCards: some View {
        VStack(spacing: 10) {
            if filteredDrivers.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bus")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.3))
                    Text("No drivers match this filter")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(filteredDrivers) { driver in
                    DriverFleetCard(driver: driver) {
                        selectedDriver = driver
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}

// MARK: - Dispatch Overview Map
struct DispatchOverviewMap: View {
    let drivers: [Driver]
    let onSelectDriver: (Driver) -> Void

    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 33.7510, longitude: -84.3880),
            span: MKCoordinateSpan(latitudeDelta: 0.022, longitudeDelta: 0.022)
        )
    )

    var body: some View {
        Map(position: $position) {
            ForEach(drivers) { driver in
                let coord = driver.route.currentStop?.coordinate
                    ?? driver.route.stops.first?.coordinate
                if let coord = coord {
                    Annotation("Bus \(driver.busNumber)", coordinate: coord) {
                        Button { onSelectDriver(driver) } label: {
                            ZStack {
                                Circle()
                                    .fill(driver.isSick ? Color(hex: "95A5A6") : driver.route.status.color)
                                    .frame(width: 38, height: 38)
                                    .shadow(color: (driver.isSick ? Color(hex: "95A5A6") : driver.route.status.color).opacity(0.5), radius: 5)
                                Image(systemName: driver.isSick ? "cross.fill" : "bus.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .overlay(alignment: .topTrailing) {
                                Text("#\(driver.busNumber)")
                                    .font(.system(size: 7, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Capsule().fill(.black.opacity(0.5)))
                                    .offset(x: 4, y: -4)
                            }
                        }
                        .buttonStyle(.plain)
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

// MARK: - Dispatch Stat Pill
struct DispatchStatPill: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(width: 70, height: 62)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.white)
                .shadow(color: .black.opacity(0.06), radius: 5, y: 2)
        )
    }
}

// MARK: - Driver Fleet Card
struct DriverFleetCard: View {
    let driver: Driver
    let onTap: () -> Void
    @ObservedObject private var chatStore = ChatStore.shared

    private var progressFraction: Double {
        guard driver.route.totalStops > 0 else { return 0 }
        return Double(driver.route.completedStops) / Double(driver.route.totalStops)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(driver.isSick ? Color(hex: "95A5A6") : driver.avatarColor)
                            .frame(width: 48, height: 48)
                        Text(String(driver.name.components(separatedBy: " ").last?.prefix(1) ?? "D"))
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .shadow(color: driver.avatarColor.opacity(0.3), radius: 5)
                    .overlay(alignment: .bottomTrailing) {
                        if driver.isSick {
                            Image(systemName: "cross.circle.fill")
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "E74C3C"))
                                .background(Circle().fill(.white).frame(width: 12, height: 12))
                        }
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(driver.name)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "1A1A2E"))
                            if driver.isSick {
                                Text("SICK")
                                    .font(.system(size: 9, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color(hex: "E74C3C")))
                            }
                        }
                        Text("Bus #\(driver.busNumber)  ·  \(driver.routeName)")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.secondary)
                        HStack(spacing: 4) {
                            Image(systemName: driver.route.status.icon)
                                .font(.system(size: 10))
                                .foregroundColor(driver.route.status.color)
                            Text(driver.route.status.label)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(driver.route.status.color)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.4))

                    // Unread message badge
                    let unread = chatStore.unreadCount(for: driver.id, as: .dispatch)
                    if unread > 0 {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "E74C3C"))
                                .frame(width: 20, height: 20)
                            Text("\(unread)")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 8)

                // Progress bar + counts
                VStack(spacing: 5) {
                    HStack {
                        Text("\(driver.route.completedStops) of \(driver.route.totalStops) stops")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(driver.route.pickedUpStudents)/\(driver.route.totalStudents) students aboard")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: "E8EDF2"))
                                .frame(height: 5)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(driver.isSick ? Color(hex: "95A5A6") : driver.route.status.color)
                                .frame(width: geo.size.width * progressFraction, height: 5)
                        }
                    }
                    .frame(height: 5)
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 14)
            }
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(.white)
                    .shadow(
                        color: driver.isSick
                            ? Color(hex: "E74C3C").opacity(0.15)
                            : .black.opacity(0.07),
                        radius: driver.isSick ? 10 : 6, y: 3
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(
                        driver.isSick ? Color(hex: "E74C3C").opacity(0.4) : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Driver Detail Sheet
struct DriverDetailSheet: View {
    let driver: Driver
    @Binding var allDrivers: [Driver]
    @ObservedObject private var chatStore = ChatStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showChat = false

    private var availableDrivers: [Driver] {
        allDrivers.filter { $0.id != driver.id && !$0.isSick && $0.route.status == .notStarted }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Route map
                    DriverRouteMapView(driver: driver)
                        .frame(height: 260)
                        .ignoresSafeArea(edges: .top)

                    // Driver info
                    driverInfoCard
                        .padding(.horizontal, 16)

                    // Reassign section (sick driver only)
                    if driver.isSick {
                        reassignCard
                            .padding(.horizontal, 16)
                    }

                    // Stop breakdown
                    stopBreakdownCard
                        .padding(.horizontal, 16)

                    Spacer().frame(height: 24)
                }
            }
            .ignoresSafeArea(edges: .top)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showChat = true
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "message.fill")
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "2F80ED"))
                            let unread = chatStore.unreadCount(for: driver.id, as: .dispatch)
                            if unread > 0 {
                                Circle()
                                    .fill(Color(hex: "E74C3C"))
                                    .frame(width: 9, height: 9)
                                    .offset(x: 3, y: -3)
                            }
                        }
                    }
                }
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(driver.isSick ? Color(hex: "95A5A6") : driver.route.status.color)
                            .frame(width: 8, height: 8)
                        Text(driver.name)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                }
            }
            .sheet(isPresented: $showChat) {
                DriverDispatchChatView(
                    driverID: driver.id,
                    driverName: driver.name,
                    viewerRole: .dispatch
                )
            }
        }
        .presentationDetents([.large])
    }

    // MARK: Driver Info Card
    private var driverInfoCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(driver.isSick ? Color(hex: "95A5A6") : driver.avatarColor)
                    .frame(width: 56, height: 56)
                Text(String(driver.name.components(separatedBy: " ").last?.prefix(1) ?? "D"))
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
            }
            .shadow(color: driver.avatarColor.opacity(0.3), radius: 6)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(driver.name)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "1A1A2E"))
                    if driver.isSick {
                        Text("SICK")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(Capsule().fill(Color(hex: "E74C3C")))
                    }
                }
                Text("Bus #\(driver.busNumber)  ·  \(driver.routeName)")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.secondary)
                HStack(spacing: 5) {
                    Image(systemName: driver.route.status.icon)
                        .font(.system(size: 11))
                        .foregroundColor(driver.route.status.color)
                    Text(driver.route.status.label)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(driver.route.status.color)
                }
            }

            Spacer()

            VStack(spacing: 6) {
                miniStat(value: "\(driver.route.completedStops)/\(driver.route.totalStops)", label: "Stops")
                miniStat(value: "\(driver.route.pickedUpStudents)/\(driver.route.totalStudents)", label: "Students")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.white)
                .shadow(color: .black.opacity(0.07), radius: 6, y: 3)
        )
    }

    private func miniStat(value: String, label: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(Color(hex: "1A1A2E"))
            Text(label)
                .font(.system(size: 9, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(width: 60, height: 40)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(hex: "F0F4F8")))
    }

    // MARK: Reassign Card
    private var reassignCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(Color(hex: "9B59B6"))
                Text("Route Reassignment Needed")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "1A1A2E"))
            }

            if availableDrivers.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    Text("No available drivers at this time. All active drivers are currently on routes.")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.secondary)
                }
            } else {
                Text("Select an available driver to assign this route:")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)

                ForEach(availableDrivers) { available in
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(available.avatarColor)
                                .frame(width: 34, height: 34)
                            Text(String(available.name.components(separatedBy: " ").last?.prefix(1) ?? ""))
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(available.name)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(hex: "1A1A2E"))
                            Text("Bus #\(available.busNumber)  ·  Standing By")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button {
                            if let idx = allDrivers.firstIndex(where: { $0.id == available.id }) {
                                allDrivers[idx].route = driver.route
                            }
                            dismiss()
                        } label: {
                            Text("Assign Route")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color(hex: "9B59B6")))
                        }
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "F8F4FF")))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(Color(hex: "9B59B6").opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: Color(hex: "9B59B6").opacity(0.1), radius: 8, y: 3)
        )
    }

    // MARK: Stop Breakdown
    private var stopBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("STOP BREAKDOWN")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
                .tracking(1.2)

            ForEach(Array(driver.route.stops.enumerated()), id: \.element.id) { idx, stop in
                HStack(spacing: 10) {
                    // Timeline connector
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(idx > 0 && idx <= driver.route.currentStopIndex
                                  ? Color(hex: "2ECC71") : Color(hex: "E8EDF2"))
                            .frame(width: 2, height: 12)

                        ZStack {
                            Circle()
                                .fill(stop.isCompleted
                                      ? Color(hex: "2ECC71")
                                      : idx == driver.route.currentStopIndex
                                        ? Color(hex: "F5A623")
                                        : Color(hex: "E8EDF2"))
                                .frame(width: 22, height: 22)
                            if stop.isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                            } else if idx == driver.route.currentStopIndex {
                                Circle().fill(.white).frame(width: 7, height: 7)
                            } else {
                                Text("\(idx + 1)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Rectangle()
                            .fill(stop.isCompleted ? Color(hex: "2ECC71") : Color(hex: "E8EDF2"))
                            .frame(width: 2, height: 12)
                            .opacity(idx < driver.route.stops.count - 1 ? 1 : 0)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(stop.name)
                            .font(.system(size: 13, weight: stop.isCompleted ? .medium : .semibold, design: .rounded))
                            .foregroundColor(stop.isCompleted ? .secondary : Color(hex: "1A1A2E"))
                            .strikethrough(stop.isCompleted, color: .secondary)
                        HStack(spacing: 4) {
                            Text("\(stop.boardingCount) students")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(.secondary)
                            Text("·")
                                .foregroundColor(.secondary)
                            Text(stop.estimatedArrival)
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    if stop.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "2ECC71"))
                            .font(.system(size: 17))
                    } else if idx == driver.route.currentStopIndex {
                        Text("NEXT")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color(hex: "F5A623")))
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.white)
                .shadow(color: .black.opacity(0.07), radius: 6, y: 3)
        )
    }
}

// MARK: - Driver Route Map (Detail Sheet)
struct DriverRouteMapView: View {
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
            // Completed route (green)
            if completedCoords.count > 1 {
                MapPolyline(coordinates: completedCoords)
                    .stroke(Color(hex: "2ECC71"), style: StrokeStyle(lineWidth: 4, lineCap: .round))
            }
            // Remaining route (blue dashed)
            if remainingCoords.count > 1 {
                MapPolyline(coordinates: remainingCoords)
                    .stroke(Color(hex: "2F80ED"), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [6, 4]))
            }

            // Stop pins
            ForEach(Array(driver.route.stops.enumerated()), id: \.element.id) { idx, stop in
                Annotation(stop.name, coordinate: stop.coordinate) {
                    ZStack {
                        Circle()
                            .fill(stop.isCompleted
                                  ? Color(hex: "2ECC71")
                                  : idx == driver.route.currentStopIndex
                                    ? Color(hex: "F5A623")
                                    : .white)
                            .frame(width: 24, height: 24)
                            .shadow(color: .black.opacity(0.15), radius: 3)
                            .overlay(
                                Circle().strokeBorder(
                                    stop.isCompleted ? Color(hex: "2ECC71") : Color(hex: "2F80ED"),
                                    lineWidth: 1.5
                                )
                            )
                        Text("\(idx + 1)")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(stop.isCompleted || idx == driver.route.currentStopIndex ? .white : Color(hex: "2F80ED"))
                    }
                }
            }

            // Bus position
            if let current = driver.route.currentStop {
                Annotation("Bus \(driver.busNumber)", coordinate: current.coordinate) {
                    ZStack {
                        Circle()
                            .fill(driver.route.status.color)
                            .frame(width: 44, height: 44)
                            .shadow(color: driver.route.status.color.opacity(0.5), radius: 10)
                        Image(systemName: "bus.fill")
                            .font(.system(size: 18, weight: .bold))
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

// MARK: - Preview
#Preview {
    DispatchDashboardView()
        .environmentObject(AppState.shared)
}
