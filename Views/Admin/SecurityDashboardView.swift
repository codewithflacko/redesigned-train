import SwiftUI

// MARK: - SecurityDashboardView
// Admin-only view showing live threat feed, severity stats, and AI-generated
// security posture report powered by Claude.

struct SecurityDashboardView: View {

    @StateObject private var vm = SecurityDashboardViewModel()

    var body: some View {
        ZStack {
            Color(hex: "0D1117").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    headerBanner
                    statsRow
                    threatFeed
                    reportSection
                    auditSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Security Center")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await vm.loadThreats() }
        .refreshable { await vm.loadThreats() }
    }

    // -------------------------------------------------------------------------
    // Header banner
    // -------------------------------------------------------------------------

    private var headerBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: "1C2A3A"))
                    .frame(width: 52, height: 52)
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(vm.overallStatusColor)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Security Monitor")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(vm.overallStatusLabel)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
            Spacer()
            // Live refresh indicator
            if vm.isLoading {
                ProgressView().tint(.white.opacity(0.5)).scaleEffect(0.8)
            } else {
                Button(action: { Task { await vm.loadThreats() } }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(hex: "161B22"))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(vm.overallStatusColor.opacity(0.35), lineWidth: 1)
                )
        )
        .padding(.top, 12)
    }

    // -------------------------------------------------------------------------
    // Severity stats row
    // -------------------------------------------------------------------------

    private var statsRow: some View {
        HStack(spacing: 10) {
            ForEach(vm.statItems, id: \.label) { item in
                StatBadge(label: item.label, count: item.count, hex: item.hex)
            }
        }
    }

    // -------------------------------------------------------------------------
    // Threat feed
    // -------------------------------------------------------------------------

    private var threatFeed: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Active Threats", icon: "exclamationmark.triangle.fill")

            if vm.threats.isEmpty && !vm.isLoading {
                emptyState
            } else {
                ForEach(vm.threats) { threat in
                    ThreatCard(threat: threat) {
                        Task { await vm.dismissThreat(id: threat.id) }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: 10) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 36))
                    .foregroundColor(Color(hex: "2ECC71"))
                Text("No threats detected")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                Text("System is operating normally")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.vertical, 30)
            Spacer()
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: "161B22"))
        )
    }

    // -------------------------------------------------------------------------
    // Report section
    // -------------------------------------------------------------------------

    private var reportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "AI Security Report", icon: "doc.text.magnifyingglass")

            if let report = vm.report {
                ReportCard(markdown: report.report_markdown, eventCount: report.total_events_analyzed)
            } else {
                generateReportButton
            }
        }
    }

    // -------------------------------------------------------------------------
    // Audit log section
    // -------------------------------------------------------------------------

    private var auditSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader(title: "Audit Log", icon: "clock.badge.checkmark.fill")
                Spacer()
                if !vm.auditEntries.isEmpty {
                    Button(vm.auditExpanded ? "Collapse" : "Show All") {
                        withAnimation(.easeInOut(duration: 0.2)) { vm.auditExpanded.toggle() }
                    }
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "AF52DE"))
                }
            }

            if vm.auditEntries.isEmpty && !vm.isLoading {
                Text("No activity recorded yet.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.white.opacity(0.35))
                    .padding(.vertical, 10)
            } else {
                let visible = vm.auditExpanded ? vm.auditEntries : Array(vm.auditEntries.prefix(5))
                VStack(spacing: 0) {
                    ForEach(Array(visible.enumerated()), id: \.element.id) { idx, entry in
                        AuditRow(entry: entry)
                        if idx < visible.count - 1 {
                            Divider().background(Color.white.opacity(0.07))
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: "161B22"))
                )
            }
        }
    }

    private var generateReportButton: some View {
        Button(action: { Task { await vm.generateReport() } }) {
            HStack(spacing: 12) {
                if vm.isGeneratingReport {
                    ProgressView().tint(.white).scaleEffect(0.9)
                    Text("Analyzing threats with Claude...")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "AF52DE"))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Generate Security Report")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Powered by Claude")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(.white.opacity(0.45))
                    }
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: "1C1A2E"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color(hex: "AF52DE").opacity(0.4), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(vm.isGeneratingReport)
    }

    // -------------------------------------------------------------------------
    // Section header
    // -------------------------------------------------------------------------

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .tracking(1.5)
        }
    }
}

// MARK: - ThreatCard

struct ThreatCard: View {
    let threat: ThreatAlert
    var onDismiss: () -> Void = {}

    var severityColor: Color { Color(hex: threat.severity.color) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header row
            HStack(spacing: 8) {
                SeverityBadge(severity: threat.severity)
                Text(threat.categoryDisplay)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                if threat.coppa_ferpa_concern {
                    CoppaTag()
                }
                Text(threat.formattedTime)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
            }

            // Explanation
            Text(threat.explanation)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(3)

            // Attack vector
            if !threat.attack_vector.isEmpty {
                Label {
                    Text(threat.attack_vector)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                } icon: {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "FF9500"))
                }
            }

            // Recommended action
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "2ECC71"))
                Text(threat.recommended_action)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "2ECC71"))
                    .lineLimit(2)
            }

            // Affected data pills
            if !threat.affected_data.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(threat.affected_data, id: \.self) { tag in
                            Text(tag.replacingOccurrences(of: "_", with: " "))
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule().fill(Color.white.opacity(0.08))
                                )
                        }
                    }
                }
            }

            // Resolve button
            HStack {
                Spacer()
                Button(action: onDismiss) {
                    Label("Resolve", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "2ECC71"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color(hex: "2ECC71").opacity(0.1))
                                .overlay(Capsule().strokeBorder(Color(hex: "2ECC71").opacity(0.35), lineWidth: 1))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: "161B22"))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(severityColor.opacity(0.25), lineWidth: 1)
                )
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(severityColor)
                .frame(width: 3)
                .padding(.vertical, 8)
                .padding(.leading, 0)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

// MARK: - Supporting sub-views

struct SeverityBadge: View {
    let severity: ThreatSeverity
    var body: some View {
        Text(severity.label)
            .font(.system(size: 9, weight: .black, design: .rounded))
            .foregroundColor(.black)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Capsule().fill(Color(hex: severity.color)))
    }
}

struct CoppaTag: View {
    var body: some View {
        Text("COPPA")
            .font(.system(size: 9, weight: .black, design: .rounded))
            .foregroundColor(Color(hex: "FF3B30"))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .overlay(
                Capsule().strokeBorder(Color(hex: "FF3B30"), lineWidth: 1)
            )
    }
}

struct StatBadge: View {
    let label: String
    let count: Int
    let hex: String

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(count > 0 ? Color(hex: hex) : .white.opacity(0.3))
            Text(label)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.45))
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "161B22"))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            count > 0 ? Color(hex: hex).opacity(0.3) : Color.clear,
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - AuditRow

struct AuditRow: View {
    let entry: AuditEntry

    var resultColor: Color {
        entry.isSuccess ? Color(hex: "2ECC71") : Color(hex: "FF3B30")
    }

    var body: some View {
        HStack(spacing: 12) {
            // Action icon
            ZStack {
                Circle()
                    .fill(resultColor.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: entry.actionIcon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(resultColor)
            }

            // Detail
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.actionLabel)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(entry.detail)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(2)
            }

            Spacer()

            // Time + result dot
            VStack(alignment: .trailing, spacing: 4) {
                Text(entry.formattedTime)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.white.opacity(0.35))
                Circle()
                    .fill(resultColor)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

struct ReportCard: View {
    let markdown: String
    let eventCount: Int
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Claude Report", systemImage: "sparkles")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "AF52DE"))
                Spacer()
                Text("\(eventCount) events analyzed")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
            }

            Text(markdown)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.white.opacity(0.75))
                .lineLimit(isExpanded ? nil : 8)

            Button(isExpanded ? "Collapse" : "Read Full Report") {
                withAnimation(.easeInOut(duration: 0.25)) { isExpanded.toggle() }
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundColor(Color(hex: "AF52DE"))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: "1C1A2E"))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color(hex: "AF52DE").opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - ViewModel

@MainActor
final class SecurityDashboardViewModel: ObservableObject {

    @Published var threats: [ThreatAlert] = []
    @Published var stats: ThreatStatsResponse? = nil
    @Published var report: SecurityReportResponse? = nil
    @Published var auditEntries: [AuditEntry] = []
    @Published var auditExpanded = false
    @Published var isLoading = false
    @Published var isGeneratingReport = false
    @Published var errorMessage: String? = nil

    private let baseURL = "http://127.0.0.1:8000"

    // -------------------------------------------------------------------------
    // Computed
    // -------------------------------------------------------------------------

    struct StatItem { let label: String; let count: Int; let hex: String }

    var statItems: [StatItem] {
        guard let s = stats else {
            return [
                StatItem(label: "CRIT",   count: 0, hex: "FF3B30"),
                StatItem(label: "HIGH",   count: 0, hex: "FF9500"),
                StatItem(label: "MED",    count: 0, hex: "FFCC00"),
                StatItem(label: "LOW",    count: 0, hex: "34AADC"),
                StatItem(label: "INFO",   count: 0, hex: "8E8E93"),
            ]
        }
        return [
            StatItem(label: "CRIT",   count: s.critical, hex: "FF3B30"),
            StatItem(label: "HIGH",   count: s.high,     hex: "FF9500"),
            StatItem(label: "MED",    count: s.medium,   hex: "FFCC00"),
            StatItem(label: "LOW",    count: s.low,      hex: "34AADC"),
            StatItem(label: "INFO",   count: s.info,     hex: "8E8E93"),
        ]
    }

    var overallStatusColor: Color {
        guard let s = stats else { return Color(hex: "8E8E93") }
        if s.critical > 0 { return Color(hex: "FF3B30") }
        if s.high > 0     { return Color(hex: "FF9500") }
        if s.medium > 0   { return Color(hex: "FFCC00") }
        if s.low > 0      { return Color(hex: "34AADC") }
        return Color(hex: "2ECC71")
    }

    var overallStatusLabel: String {
        guard let s = stats else { return "Connecting to security monitor..." }
        if s.critical > 0 { return "\(s.critical) critical threat(s) require immediate attention" }
        if s.high > 0     { return "\(s.high) high-severity threat(s) detected" }
        if s.medium > 0   { return "\(s.medium) medium-severity issue(s) under review" }
        if s.total > 0    { return "Minor anomalies detected — low risk" }
        return "All systems secure — no threats detected"
    }

    // -------------------------------------------------------------------------
    // Network
    // -------------------------------------------------------------------------

    func loadThreats() async {
        isLoading = true
        defer { isLoading = false }

        async let threatsResult = fetch(ThreatListResponse.self,  path: "/security/threats?limit=50")
        async let statsResult   = fetch(ThreatStatsResponse.self, path: "/security/stats")
        async let auditResult   = fetch(AuditLogResponse.self,    path: "/security/audit?limit=50")

        if let t = try? await threatsResult { threats      = t.threats }
        if let s = try? await statsResult   { stats        = s }
        if let a = try? await auditResult   { auditEntries = a.entries }
    }

    func generateReport() async {
        isGeneratingReport = true
        defer { isGeneratingReport = false }

        if let r = try? await fetch(SecurityReportResponse.self, path: "/security/report") {
            report = r
        }
    }

    func dismissThreat(id: String) async {
        // Optimistic update — remove from list immediately so the UI responds instantly
        withAnimation(.easeOut(duration: 0.25)) {
            threats.removeAll { $0.id == id }
        }

        // PATCH the backend
        guard let url   = URL(string: "\(baseURL)/security/threats/\(id)/dismiss"),
              let token = AuthManager.shared.accessToken else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        _ = try? await URLSession.shared.data(for: req)

        // Refresh stats and audit log to reflect dismissal
        async let statsRefresh = fetch(ThreatStatsResponse.self, path: "/security/stats")
        async let auditRefresh = fetch(AuditLogResponse.self,    path: "/security/audit?limit=50")
        if let s = try? await statsRefresh { stats        = s }
        if let a = try? await auditRefresh { auditEntries = a.entries }
    }

    private func fetch<T: Decodable>(_ type: T.Type, path: String) async throws -> T {
        guard let url   = URL(string: "\(baseURL)\(path)"),
              let token = AuthManager.shared.accessToken else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

#Preview {
    NavigationStack {
        SecurityDashboardView()
    }
}
