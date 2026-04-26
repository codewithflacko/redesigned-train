import SwiftUI

// MARK: - Incident Model
struct Incident: Identifiable {
    let id = UUID()
    let driverName: String
    let busNumber: String
    let routeName: String
    let type: IncidentType
    let time: String
    var isResolved: Bool = false

    enum IncidentType {
        case delayed(reason: String)
        case paused(reason: String)
        case sickDriver

        var label: String {
            switch self {
            case .delayed(let r): return "Delayed — \(r)"
            case .paused(let r):  return "Paused — \(r)"
            case .sickDriver:     return "Driver Reported Sick"
            }
        }
        var icon: String {
            switch self {
            case .delayed:    return "exclamationmark.triangle.fill"
            case .paused:     return "pause.circle.fill"
            case .sickDriver: return "cross.circle.fill"
            }
        }
        var color: Color {
            switch self {
            case .delayed:    return Color(hex: "E74C3C")
            case .paused:     return Color(hex: "F5A623")
            case .sickDriver: return Color(hex: "95A5A6")
            }
        }
    }
}

// MARK: - Admin Dashboard
struct AdminDashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: AdminTab = .overview
    @State private var incidents: [Incident] = AdminDashboardView.buildIncidents()
    @State private var showPresentation = false
    @Environment(\.dismiss) private var dismiss

    private var drivers: [Driver] { appState.drivers }

    enum AdminTab: String, CaseIterable {
        case overview    = "Overview"
        case routes      = "Routes"
        case attendance  = "Attendance"
        case incidents   = "Incidents"
        case statistics  = "Statistics"
        case security    = "Security"

        var icon: String {
            switch self {
            case .overview:    return "chart.bar.fill"
            case .routes:      return "map.fill"
            case .attendance:  return "person.3.fill"
            case .incidents:   return "exclamationmark.triangle.fill"
            case .statistics:  return "chart.line.uptrend.xyaxis"
            case .security:    return "shield.lefthalf.filled"
            }
        }
    }

    // MARK: Computed Stats
    private var allStudents: [RouteStudent] {
        drivers.flatMap { $0.route.stops.flatMap { $0.students } }
    }
    private var absentStudents: [(student: RouteStudent, stop: String, driver: String)] {
        drivers.flatMap { driver in
            driver.route.stops.flatMap { stop in
                stop.students.filter { $0.isAbsentToday }.map { student in
                    (student: student, stop: stop.name, driver: driver.name)
                }
            }
        }
    }
    private var pickedUpCount:  Int { allStudents.filter { $0.isPickedUp }.count }
    private var absentCount:    Int { allStudents.filter { $0.isAbsentToday }.count }
    private var totalStudents:  Int { allStudents.count }
    private var arrivedRoutes:  Int { drivers.filter { $0.route.status == .completed }.count }
    private var activeRoutes:   Int { drivers.filter { $0.route.status == .inProgress }.count }
    private var onTimePercent:  Int {
        guard !drivers.isEmpty else { return 0 }
        let ok = drivers.filter {
            if case .delayed = $0.route.status { return false }
            return true
        }.count
        return Int((Double(ok) / Double(drivers.count)) * 100)
    }
    private var activeIncidents: [Incident] { incidents.filter { !$0.isResolved } }

    static func buildIncidents() -> [Incident] {
        var list: [Incident] = []
        for d in Driver.sampleDrivers {
            if d.isSick {
                list.append(Incident(driverName: d.name, busNumber: d.busNumber,
                                     routeName: d.routeName, type: .sickDriver, time: "Today"))
            }
            switch d.route.status {
            case .delayed(let r):
                list.append(Incident(driverName: d.name, busNumber: d.busNumber,
                                     routeName: d.routeName, type: .delayed(reason: r.rawValue), time: "7:31 AM"))
            case .paused(let r):
                list.append(Incident(driverName: d.name, busNumber: d.busNumber,
                                     routeName: d.routeName, type: .paused(reason: r.rawValue), time: "7:28 AM"))
            default: break
            }
        }
        return list
    }

    var body: some View {
        ZStack {
            Color(hex: "F5F0FF").ignoresSafeArea()
            VStack(spacing: 0) {
                headerBar
                tabBar
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        switch selectedTab {
                        case .overview:    overviewTab
                        case .routes:      routesTab
                        case .attendance:  attendanceTab
                        case .incidents:   incidentsTab
                        case .statistics:  StatisticsView()
                        case .security:    SecurityDashboardView()
                        }
                        Spacer().frame(height: 24)
                    }
                    .padding(.top, 16)
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showPresentation) {
            BusStatsPresentationView()
        }
    }

    // MARK: - Header
    private var headerBar: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "4A1A6B"), Color(hex: "8E44AD")],
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
                    Text("Riverside Elementary")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text("Admin Dashboard")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                if activeIncidents.count > 0 {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                        Circle()
                            .fill(Color(hex: "E74C3C"))
                            .frame(width: 14, height: 14)
                            .overlay(
                                Text("\(activeIncidents.count)")
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 4, y: -4)
                    }
                } else {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .frame(height: 60)
    }

    // MARK: - Tab Bar
    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(AdminTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.3)) { selectedTab = tab }
                    } label: {
                        VStack(spacing: 4) {
                            HStack(spacing: 5) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 12, weight: .semibold))
                                Text(tab.rawValue)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                if tab == .incidents && activeIncidents.count > 0 {
                                    Text("\(activeIncidents.count)")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background(Capsule().fill(Color(hex: "E74C3C")))
                                }
                            }
                            .foregroundColor(selectedTab == tab ? Color(hex: "8E44AD") : .secondary)

                            Rectangle()
                                .fill(selectedTab == tab ? Color(hex: "8E44AD") : Color.clear)
                                .frame(height: 2)
                                .cornerRadius(1)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .background(.white)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: - Overview Tab
    private var overviewTab: some View {
        VStack(spacing: 16) {
            // Stats grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                AdminStatCard(value: "\(drivers.count)", label: "Total Buses", icon: "bus.fill", color: Color(hex: "2F80ED"))
                AdminStatCard(value: "\(onTimePercent)%", label: "On Time", icon: "checkmark.circle.fill", color: Color(hex: "2ECC71"))
                AdminStatCard(value: "\(activeRoutes)", label: "Active Routes", icon: "location.fill", color: Color(hex: "F5A623"))
                AdminStatCard(value: "\(arrivedRoutes)", label: "Completed", icon: "checkmark.seal.fill", color: Color(hex: "8E44AD"))
            }
            .padding(.horizontal, 16)

            // Student summary
            studentSummaryCard

            // Active incidents preview
            if !activeIncidents.isEmpty {
                activeIncidentsBanner
            }

            // Present Stats button
            Button {
                showPresentation = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Present Impact Stats")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                    Spacer()
                    Image(systemName: "play.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "4A1A6B"), Color(hex: "8E44AD")],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color(hex: "8E44AD").opacity(0.35), radius: 8, y: 4)
            }
            .padding(.horizontal, 16)
        }
    }

    private var studentSummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("TODAY'S STUDENTS")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
                .tracking(1.2)

            HStack(spacing: 0) {
                studentStat(value: totalStudents, label: "Total", color: Color(hex: "2F80ED"))
                Divider().frame(height: 40)
                studentStat(value: totalStudents - absentCount, label: "Present", color: Color(hex: "2ECC71"))
                Divider().frame(height: 40)
                studentStat(value: pickedUpCount, label: "Picked Up", color: Color(hex: "F5A623"))
                Divider().frame(height: 40)
                studentStat(value: absentCount, label: "Absent", color: Color(hex: "E74C3C"))
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.white)
                .shadow(color: .black.opacity(0.07), radius: 6, y: 3)
        )
        .padding(.horizontal, 16)
    }

    private func studentStat(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var activeIncidentsBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Color(hex: "E74C3C"))
                Text("ACTIVE INCIDENTS")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "E74C3C"))
                    .tracking(1.2)
            }

            ForEach(activeIncidents.prefix(2)) { incident in
                HStack(spacing: 10) {
                    Image(systemName: incident.type.icon)
                        .foregroundColor(incident.type.color)
                        .font(.system(size: 14))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(incident.driverName) — Bus #\(incident.busNumber)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(hex: "1A1A2E"))
                        Text(incident.type.label)
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(incident.time)
                        .font(.system(size: 10, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(incident.type.color.opacity(0.08)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.white)
                .shadow(color: .black.opacity(0.07), radius: 6, y: 3)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Routes Tab
    private var routesTab: some View {
        VStack(spacing: 10) {
            ForEach(drivers) { driver in
                AdminRouteCard(driver: driver)
                    .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Attendance Tab
    private var attendanceTab: some View {
        VStack(spacing: 16) {
            // Summary bar
            HStack(spacing: 12) {
                attendancePill(value: totalStudents - absentCount, label: "Present", color: Color(hex: "2ECC71"))
                attendancePill(value: absentCount, label: "Absent", color: Color(hex: "E74C3C"))
            }
            .padding(.horizontal, 16)

            if absentStudents.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(Color(hex: "2ECC71"))
                    Text("No absences reported today")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("ABSENT TODAY")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                        .tracking(1.2)
                        .padding(.horizontal, 16)

                    ForEach(absentStudents, id: \.student.id) { entry in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "E74C3C").opacity(0.12))
                                    .frame(width: 40, height: 40)
                                Text(String(entry.student.name.prefix(1)))
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: "E74C3C"))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.student.name)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color(hex: "1A1A2E"))
                                Text("Grade \(entry.student.grade)  ·  \(entry.stop)")
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Text(entry.driver)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.trailing)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.white)
                                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                        )
                        .padding(.horizontal, 16)
                    }
                }
            }
        }
    }

    private func attendancePill(value: Int, label: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Text("\(value)")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.white)
                .shadow(color: .black.opacity(0.07), radius: 5, y: 2)
        )
    }

    // MARK: - Incidents Tab
    private var incidentsTab: some View {
        VStack(spacing: 10) {
            if incidents.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 44))
                        .foregroundColor(Color(hex: "2ECC71"))
                    Text("No incidents today")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach($incidents) { $incident in
                    AdminIncidentCard(incident: $incident)
                        .padding(.horizontal, 16)
                }
            }
        }
    }
}


// MARK: - Admin Stat Card
struct AdminStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                Spacer()
            }
            Text(value)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(Color(hex: "1A1A2E"))
            Text(label)
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.white)
                .shadow(color: .black.opacity(0.07), radius: 6, y: 3)
        )
    }
}

// MARK: - Admin Route Card
struct AdminRouteCard: View {
    let driver: Driver

    private var progressFraction: Double {
        guard driver.route.totalStops > 0 else { return 0 }
        return Double(driver.route.completedStops) / Double(driver.route.totalStops)
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(driver.isSick ? Color(hex: "95A5A6") : driver.avatarColor)
                        .frame(width: 44, height: 44)
                    Text(String(driver.name.components(separatedBy: " ").last?.prefix(1) ?? "D"))
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }
                .shadow(color: driver.avatarColor.opacity(0.3), radius: 4)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(driver.name)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "1A1A2E"))
                        if driver.isSick {
                            Text("SICK")
                                .font(.system(size: 8, weight: .black))
                                .foregroundColor(.white)
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(Capsule().fill(Color(hex: "E74C3C")))
                        }
                    }
                    Text("Bus #\(driver.busNumber)  ·  \(driver.routeName)")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(spacing: 3) {
                    Circle()
                        .fill(driver.route.status.color)
                        .frame(width: 9, height: 9)
                    Text(shortStatus(driver.route.status))
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(driver.route.status.color)
                }
            }

            VStack(spacing: 4) {
                HStack {
                    Text("\(driver.route.completedStops)/\(driver.route.totalStops) stops  ·  \(driver.route.pickedUpStudents)/\(driver.route.totalStudents) students")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4).fill(Color(hex: "E8EDF2")).frame(height: 5)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(driver.route.status.color)
                            .frame(width: geo.size.width * progressFraction, height: 5)
                    }
                }
                .frame(height: 5)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .black.opacity(0.07), radius: 6, y: 3)
        )
    }

    private func shortStatus(_ s: RouteStatus) -> String {
        switch s {
        case .notStarted: return "Ready"
        case .inProgress: return "Active"
        case .paused:     return "Paused"
        case .delayed:    return "Delayed"
        case .completed:  return "Done"
        }
    }
}

// MARK: - Admin Incident Card
struct AdminIncidentCard: View {
    @Binding var incident: Incident

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(incident.type.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: incident.type.icon)
                    .font(.system(size: 18))
                    .foregroundColor(incident.type.color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("\(incident.driverName) — Bus #\(incident.busNumber)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "1A1A2E"))
                Text(incident.type.label)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.secondary)
                Text(incident.routeName + "  ·  " + incident.time)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                withAnimation { incident.isResolved = true }
            } label: {
                Text(incident.isResolved ? "Resolved" : "Resolve")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(incident.isResolved ? .secondary : .white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(incident.isResolved ? Color(hex: "E8EDF2") : Color(hex: "8E44AD"))
                    )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            incident.isResolved ? Color.clear : incident.type.color.opacity(0.3),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: .black.opacity(0.07), radius: 6, y: 3)
        )
        .opacity(incident.isResolved ? 0.5 : 1.0)
    }
}

#Preview {
    AdminDashboardView()
        .environmentObject(AppState.shared)
}
