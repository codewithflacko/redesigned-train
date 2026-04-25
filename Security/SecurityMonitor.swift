import Foundation
import UIKit

// MARK: - SecurityMonitor
//
// Singleton that captures security events from anywhere in the app and
// fire-and-forgets them to the backend. Never blocks the UI thread.
//
// Usage:
//   SecurityMonitor.shared.report(.loginFailed, context: ["email": email])

final class SecurityMonitor {
    static let shared = SecurityMonitor()
    private init() {}

    // ---------------------------------------------------------------------------
    // Config — point at your running backend
    // ---------------------------------------------------------------------------

    private let baseURL = "http://127.0.0.1:8000"

    // Chat rate-limiting state (local, for flagging)
    private var chatTimestamps: [Date] = []
    private let chatRateWindowSec: TimeInterval = 30
    private let chatRateThreshold = 10

    // ---------------------------------------------------------------------------
    // Primary report method — always fire-and-forget
    // ---------------------------------------------------------------------------

    func report(
        _ eventType: SecurityEventType,
        userId: String? = nil,
        role: UserRole? = nil,
        context: [String: String] = [:]
    ) {
        Task { @MainActor in
            let resolvedUserId = userId ?? AuthManager.shared.userId
            let resolvedRole   = role   ?? AuthManager.shared.currentRole

            let payload = SecurityEventPayload(
                eventType: eventType,
                userId:    resolvedUserId,
                role:      resolvedRole,
                context:   context
            )

            await send(payload)
        }
    }

    // ---------------------------------------------------------------------------
    // Convenience reporters — called from specific app features
    // ---------------------------------------------------------------------------

    /// Call from login views on every failed attempt
    func reportFailedLogin(email: String, role: UserRole) {
        report(.loginFailed, context: ["email": email, "attempted_role": role.rawValue])
    }

    /// Call from login views on successful login
    func reportSuccessfulLogin(userId: String, role: UserRole) {
        report(.loginSuccess, userId: userId, role: role)
    }

    /// Call from ParentDashboard when child list loads
    /// - owned: true if the parent owns this child record
    func reportChildDataAccess(childId: String, owned: Bool) {
        report(
            .childDataLoaded,
            context: ["child_id": childId, "owned": owned ? "true" : "false"]
        )
    }

    /// Call from DriverDashboard when GPS coordinate is updated
    /// - isAnomaly: set true if coordinates jumped suspiciously fast
    func reportGPSUpdate(lat: Double, lon: Double, isAnomaly: Bool = false) {
        guard isAnomaly else { return }  // Only send anomalies to reduce noise
        report(
            .gpsUpdate,
            context: [
                "lat":     String(lat),
                "lon":     String(lon),
                "anomaly": "true",
            ]
        )
    }

    /// Call from DispatchDashboard when a route is reassigned
    func reportRouteReassignment(fromDriverId: String, toDriverId: String, authorizedByAdmin: Bool) {
        report(
            .routeReassignment,
            context: [
                "from_driver":    fromDriverId,
                "to_driver":      toDriverId,
                "admin_approved": authorizedByAdmin ? "true" : "false",
            ]
        )
    }

    /// Call from ChatStore.send() — automatically flags if rate limit exceeded
    func reportChatMessage(driverId: String, sender: String) {
        let now = Date()
        // Clean old timestamps outside window
        chatTimestamps = chatTimestamps.filter { now.timeIntervalSince($0) < chatRateWindowSec }
        chatTimestamps.append(now)

        let rateFlag = chatTimestamps.count > chatRateThreshold
        report(
            .chatMessageSent,
            context: [
                "driver_id":  driverId,
                "sender":     sender,
                "rate_flag":  rateFlag ? "true" : "false",
            ]
        )
    }

    /// Call from AdminDashboard bulk student data loads
    func reportBulkDataAccess(recordCount: Int, dataType: String) {
        guard recordCount > 20 else { return }
        report(
            .bulkDataAccess,
            context: [
                "record_count": String(recordCount),
                "data_type":    dataType,
            ]
        )
    }

    // ---------------------------------------------------------------------------
    // Network
    // ---------------------------------------------------------------------------

    private func send(_ payload: SecurityEventPayload) async {
        guard let url = URL(string: "\(baseURL)/security/event") else { return }
        let token = await MainActor.run { AuthManager.shared.accessToken }
        guard let token else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 5  // don't hang the background task

        do {
            request.httpBody = try JSONEncoder().encode(payload)
            _ = try await NetworkSession.pinned.data(for: request)
        } catch {
            // Silent failure — security monitoring must never crash the app
        }
    }
}
