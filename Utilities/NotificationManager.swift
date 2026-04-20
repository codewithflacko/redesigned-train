import Foundation
import UserNotifications

// MARK: - NotificationManager
//
// Schedules local notifications for cross-role events:
//   • Parent  ← bus 2 stops away, bus 1 stop away, child arrived at school
//   • Driver  ← parent marked a student absent
//
// All notifications fire after a 1-second delay so they feel like a push
// even though they originate locally from AppState mutations.

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    // -----------------------------------------------------------------------
    // Permission
    // -----------------------------------------------------------------------

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { _, _ in }
    }

    // -----------------------------------------------------------------------
    // Parent notifications — bus proximity + arrival
    // -----------------------------------------------------------------------

    /// Fire when stopsAway drops to 2 or 1.
    func sendBusNearbyAlert(childName: String, stopsAway: Int, busNumber: String, childId: UUID) {
        let content = UNMutableNotificationContent()
        content.sound = .default
        if stopsAway == 1 {
            content.title = "Bus is next stop!"
            content.body  = "Get \(childName) outside now — Bus #\(busNumber) is one stop away."
        } else {
            content.title = "Bus is \(stopsAway) stops away"
            content.body  = "Bus #\(busNumber) is approaching. Get \(childName) ready to go."
        }
        schedule(content, id: "bus-nearby-\(childId)")
    }

    /// Fire when the driver's route completes and the child's status flips to arrived.
    func sendArrivedAlert(childName: String, schoolName: String, childId: UUID) {
        let content = UNMutableNotificationContent()
        content.title = "\(childName) has arrived!"
        content.body  = "\(childName) safely arrived at \(schoolName)."
        content.sound = .default
        schedule(content, id: "arrived-\(childId)")
    }

    // -----------------------------------------------------------------------
    // Driver notifications — student absence
    // -----------------------------------------------------------------------

    /// Fire when a parent marks their child absent, so the driver knows to skip.
    func sendAbsenceAlert(studentName: String, busNumber: String, stopName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Student marked absent"
        content.body  = "\(studentName) at \(stopName) is absent today. Skip that pickup."
        content.sound = .default
        schedule(content, id: "absent-\(studentName)-\(busNumber)")
    }

    // -----------------------------------------------------------------------
    // Internal
    // -----------------------------------------------------------------------

    private func schedule(_ content: UNMutableNotificationContent, id: String) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("[NotificationManager] Failed to schedule '\(id)': \(error.localizedDescription)")
            }
        }
    }
}
