import SwiftUI

// MARK: - Message Sender
enum MessageSender: Equatable {
    case driver, dispatch
    var label: String { self == .driver ? "Driver" : "Dispatch" }
}

// MARK: - Chat Message
struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let sender: MessageSender
    let timestamp: Date
    var isRead: Bool = false
}

// MARK: - Chat Store (shared singleton)
class ChatStore: ObservableObject {
    static let shared = ChatStore()

    @Published var threads: [UUID: [ChatMessage]] = [:]

    // MARK: - Accessors
    func messages(for driverID: UUID) -> [ChatMessage] {
        threads[driverID] ?? []
    }

    func unreadCount(for driverID: UUID, as reader: MessageSender) -> Int {
        messages(for: driverID).filter { $0.sender != reader && !$0.isRead }.count
    }

    func totalUnread(as reader: MessageSender) -> Int {
        threads.values.flatMap { $0 }.filter { $0.sender != reader && !$0.isRead }.count
    }

    // MARK: - Send
    func send(text: String, from sender: MessageSender, driverID: UUID) {
        var msgs = threads[driverID] ?? []
        msgs.append(ChatMessage(text: text, sender: sender, timestamp: Date()))
        threads[driverID] = msgs
    }

    // MARK: - Mark read
    func markRead(driverID: UUID, as reader: MessageSender) {
        guard var msgs = threads[driverID] else { return }
        for i in msgs.indices where msgs[i].sender != reader {
            msgs[i].isRead = true
        }
        threads[driverID] = msgs
    }

    // MARK: - Seed sample thread
    func seedIfNeeded(driverID: UUID, driverFirstName: String) {
        guard threads[driverID] == nil else { return }
        threads[driverID] = [
            ChatMessage(
                text: "Good morning \(driverFirstName)! Route looks clear today, no reported incidents ahead.",
                sender: .dispatch,
                timestamp: Date().addingTimeInterval(-3600),
                isRead: true
            ),
            ChatMessage(
                text: "Thanks! Starting my route now.",
                sender: .driver,
                timestamp: Date().addingTimeInterval(-3540),
                isRead: true
            ),
            ChatMessage(
                text: "Running about 5 min late at Oak Street — light traffic.",
                sender: .driver,
                timestamp: Date().addingTimeInterval(-900),
                isRead: false
            ),
        ]
    }
}
