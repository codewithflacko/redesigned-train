import Foundation
import UIKit

// MARK: - User Role

enum UserRole: String, Codable, CaseIterable {
    case parent   = "parent"
    case driver   = "driver"
    case dispatch = "dispatch"
    case admin    = "admin"

    var displayName: String {
        switch self {
        case .parent:   return "Parent"
        case .driver:   return "Driver"
        case .dispatch: return "Dispatch"
        case .admin:    return "Admin"
        }
    }
}

// MARK: - Threat Severity

enum ThreatSeverity: String, Codable {
    case critical = "CRITICAL"
    case high     = "HIGH"
    case medium   = "MEDIUM"
    case low      = "LOW"
    case info     = "INFO"

    var color: String {
        switch self {
        case .critical: return "FF3B30"
        case .high:     return "FF9500"
        case .medium:   return "FFCC00"
        case .low:      return "34AADC"
        case .info:     return "8E8E93"
        }
    }

    var label: String { rawValue.capitalized }

    var priority: Int {
        switch self {
        case .critical: return 5
        case .high:     return 4
        case .medium:   return 3
        case .low:      return 2
        case .info:     return 1
        }
    }
}

// MARK: - Security Event Types (mirrors backend SecurityEventType)

enum SecurityEventType: String, Codable {
    // Auth
    case loginFailed         = "login_failed"
    case loginSuccess        = "login_success"
    case loginAfterHours     = "login_after_hours"
    case roleMismatch        = "role_mismatch"
    // Data access
    case childDataLoaded     = "child_data_loaded"
    case bulkDataAccess      = "bulk_data_access"
    case coppaExportAttempt  = "coppa_export_attempt"
    // Location
    case gpsUpdate           = "gps_update"
    case locationOutOfBounds = "location_out_of_bounds"
    // Operational
    case routeReassignment   = "route_reassignment"
    case driverSickReport    = "driver_sick_report"
    // Chat
    case chatMessageSent     = "chat_message_sent"
    // Session
    case concurrentSession   = "concurrent_session"
}

// MARK: - Security Event (sent to backend)

struct SecurityEventPayload: Encodable {
    let event_type: String
    let user_id: String?
    let role: String?
    let context: [String: String]
    let device_id: String
    let timestamp: String

    init(
        eventType: SecurityEventType,
        userId: String? = nil,
        role: UserRole? = nil,
        context: [String: String] = [:]
    ) {
        self.event_type = eventType.rawValue
        self.user_id    = userId
        self.role       = role?.rawValue
        self.context    = context
        self.device_id  = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        let formatter   = ISO8601DateFormatter()
        self.timestamp  = formatter.string(from: Date())
    }
}

// MARK: - Threat Alert (received from backend)

struct ThreatAlert: Identifiable, Decodable {
    let id: String
    let severity: ThreatSeverity
    let threat_category: String
    let attack_vector: String
    let affected_data: [String]
    let recommended_action: String
    let coppa_ferpa_concern: Bool
    let explanation: String
    let source_event_type: String
    let user_id: String?
    let role: String?
    let timestamp: String
    let context: [String: String]
    let dismissed: Bool

    var categoryDisplay: String {
        threat_category
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }

    var formattedTime: String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let iso2 = ISO8601DateFormatter()
        guard let date = iso.date(from: timestamp) ?? iso2.date(from: timestamp) else {
            return timestamp
        }
        let df = DateFormatter()
        df.timeStyle = .short
        df.dateStyle = .none
        return df.string(from: date)
    }
}

// MARK: - Threat List Response

struct ThreatListResponse: Decodable {
    let threats: [ThreatAlert]
    let total: Int
}

// MARK: - Threat Stats

struct ThreatStatsResponse: Decodable {
    let critical: Int
    let high: Int
    let medium: Int
    let low: Int
    let info: Int
    let total: Int
    let by_category: [String: Int]
}

// MARK: - Security Report

struct SecurityReportResponse: Decodable {
    let generated_at: String
    let report_markdown: String
    let total_events_analyzed: Int
}

// MARK: - Audit Log

struct AuditEntry: Identifiable, Decodable {
    let id: String
    let timestamp: String
    let actor_id: String?
    let actor_email: String
    let actor_role: String
    let action: String
    let resource: String
    let result: String
    let detail: String

    var isSuccess: Bool { result == "success" }

    var actionIcon: String {
        switch action {
        case "LOGIN_SUCCESS":       return "person.fill.checkmark"
        case "LOGIN_FAILURE":       return "person.fill.xmark"
        case "LOGIN_ROLE_MISMATCH": return "exclamationmark.shield.fill"
        case "LOGOUT":              return "door.right.hand.open"
        case "THREAT_DISMISSED":    return "checkmark.shield.fill"
        case "REPORT_GENERATED":    return "doc.text.magnifyingglass"
        default:                    return "clock.fill"
        }
    }

    var actionLabel: String {
        action.replacingOccurrences(of: "_", with: " ").capitalized
    }

    var formattedTime: String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let iso2 = ISO8601DateFormatter()
        guard let date = iso.date(from: timestamp) ?? iso2.date(from: timestamp) else {
            return timestamp
        }
        let df = DateFormatter()
        df.timeStyle = .short
        df.dateStyle = .short
        return df.string(from: date)
    }
}

struct AuditLogResponse: Decodable {
    let entries: [AuditEntry]
    let total: Int
}

struct LoginRequestPayload: Encodable {
    let email: String
    let password: String
    let role: String
}

struct LoginResponsePayload: Decodable {
    let access_token: String
    let token_type: String
    let role: String
    let user_id: String
}
