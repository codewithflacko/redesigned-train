import SwiftUI

// MARK: - Notification Model
enum ParentNotifType {
    case busNearby(stops: Int)
    case childPickedUp
    case busDelayed
    case busResumed
    case arrived
    case routeStarted
    case absenceConfirmed

    var icon: String {
        switch self {
        case .busNearby:         return "bus.fill"
        case .childPickedUp:     return "checkmark.circle.fill"
        case .busDelayed:        return "clock.badge.exclamationmark.fill"
        case .busResumed:        return "play.circle.fill"
        case .arrived:           return "building.columns.fill"
        case .routeStarted:      return "flag.fill"
        case .absenceConfirmed:  return "moon.zzz.fill"
        }
    }

    var color: Color {
        switch self {
        case .busNearby(let s): return s <= 1 ? Color(hex: "E74C3C") : Color(hex: "E67E22")
        case .childPickedUp:    return Color(hex: "2ECC71")
        case .busDelayed:       return Color(hex: "E74C3C")
        case .busResumed:       return Color(hex: "2F80ED")
        case .arrived:          return Color(hex: "2ECC71")
        case .routeStarted:     return Color(hex: "2F80ED")
        case .absenceConfirmed: return .secondary
        }
    }
}

struct ParentNotification: Identifiable {
    let id = UUID()
    let childName: String
    let type: ParentNotifType
    let body: String
    let timestamp: String
    var isRead: Bool = false

    // Sample feed for demo
    static let samples: [ParentNotification] = [
        ParentNotification(
            childName: "Emma",
            type: .busNearby(stops: 1),
            body: "Bus #42 is 1 stop away — get Emma outside now!",
            timestamp: "Just now"
        ),
        ParentNotification(
            childName: "Liam",
            type: .childPickedUp,
            body: "Liam has been picked up at Oak Street & 5th Ave.",
            timestamp: "8 min ago",
            isRead: true
        ),
        ParentNotification(
            childName: "Emma",
            type: .busNearby(stops: 3),
            body: "Bus #42 is 3 stops away. ETA 8:14 AM.",
            timestamp: "14 min ago",
            isRead: true
        ),
        ParentNotification(
            childName: "Mia",
            type: .arrived,
            body: "Mia has arrived safely at Riverside Elementary.",
            timestamp: "22 min ago",
            isRead: true
        ),
        ParentNotification(
            childName: "Liam",
            type: .busDelayed,
            body: "Bus #38 is running about 10 min late due to traffic.",
            timestamp: "31 min ago",
            isRead: true
        ),
        ParentNotification(
            childName: "Emma",
            type: .routeStarted,
            body: "Bus #42 has started its morning route. Driver: Mr. Mark.",
            timestamp: "47 min ago",
            isRead: true
        ),
        ParentNotification(
            childName: "Mia",
            type: .busResumed,
            body: "Bus #12 has resumed the route after a brief stop.",
            timestamp: "1 hr ago",
            isRead: true
        ),
        ParentNotification(
            childName: "Liam",
            type: .absenceConfirmed,
            body: "Liam is marked absent today. Driver has been notified.",
            timestamp: "Yesterday",
            isRead: true
        ),
    ]
}

// MARK: - Notification Center Sheet
struct NotificationCenterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var notifications: [ParentNotification]

    private var unreadCount: Int { notifications.filter { !$0.isRead }.count }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F2F6FA").ignoresSafeArea()

                if notifications.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            // Mark all read button
                            if unreadCount > 0 {
                                Button(action: markAllRead) {
                                    Text("Mark all as read")
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundColor(Color(hex: "2F80ED"))
                                }
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .padding(.horizontal, 20)
                                .padding(.top, 12)
                                .padding(.bottom, 4)
                            }

                            LazyVStack(spacing: 10) {
                                ForEach(notifications) { notif in
                                    NotificationRow(notification: notif)
                                        .padding(.horizontal, 16)
                                        .onTapGesture { markRead(id: notif.id) }
                                }
                            }
                            .padding(.vertical, 12)
                        }
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "2F80ED"))
                }
            }
        }
    }

    // MARK: - Helpers
    private func markAllRead() {
        withAnimation {
            for i in notifications.indices { notifications[i].isRead = true }
        }
    }

    private func markRead(id: UUID) {
        if let idx = notifications.firstIndex(where: { $0.id == id }) {
            withAnimation { notifications[idx].isRead = true }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 44))
                .foregroundColor(.secondary.opacity(0.4))
            Text("No Notifications")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "1A1A2E"))
            Text("You're all caught up! Updates about\nyour children's bus will appear here.")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Notification Row
struct NotificationRow: View {
    let notification: ParentNotification

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon bubble
            ZStack {
                Circle()
                    .fill(notification.type.color.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: notification.type.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(notification.type.color)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(notification.childName)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(hex: "1A1A2E"))
                    Spacer()
                    Text(notification.timestamp)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.secondary)
                    if !notification.isRead {
                        Circle()
                            .fill(Color(hex: "2F80ED"))
                            .frame(width: 8, height: 8)
                    }
                }

                Text(notification.body)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(notification.isRead ? .secondary : Color(hex: "1A1A2E"))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(notification.isRead ? Color.white : Color(hex: "EEF5FF"))
                .shadow(color: .black.opacity(notification.isRead ? 0.05 : 0.08), radius: 6, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    notification.isRead ? Color.clear : Color(hex: "2F80ED").opacity(0.2),
                    lineWidth: 1
                )
        )
        .animation(.easeInOut(duration: 0.2), value: notification.isRead)
    }
}

#Preview {
    @Previewable @State var notifs = ParentNotification.samples
    NotificationCenterView(notifications: $notifs)
}
