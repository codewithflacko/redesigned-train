import SwiftUI

// MARK: - Driver ↔ Dispatch Chat View
struct DriverDispatchChatView: View {
    let driverID: UUID
    let driverName: String
    let viewerRole: MessageSender          // who is looking (.driver or .dispatch)

    @ObservedObject private var store = ChatStore.shared
    @Environment(\.dismiss) private var dismiss

    @State private var inputText = ""
    @State private var scrollProxy: ScrollViewProxy? = nil
    @FocusState private var inputFocused: Bool

    // Quick-reply presets (shown only for driver — big tap targets)
    private let driverQuickReplies = [
        "Running 5 min late",
        "At the stop now",
        "En route to next stop",
        "Bus issue — need help",
        "All students on board",
        "Route complete ✅",
    ]

    private var messages: [ChatMessage] { store.messages(for: driverID) }
    private var isDriver: Bool { viewerRole == .driver }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Chat bubble list
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 8) {
                            ForEach(messages) { msg in
                                MessageBubble(message: msg, viewerRole: viewerRole)
                                    .id(msg.id)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .onAppear {
                        scrollProxy = proxy
                        store.seedIfNeeded(driverID: driverID,
                                          driverFirstName: driverName.components(separatedBy: " ").first ?? driverName)
                        store.markRead(driverID: driverID, as: viewerRole)
                        scrollToBottom(proxy: proxy, animated: false)
                    }
                    .onChange(of: messages.count) {
                        scrollToBottom(proxy: proxy, animated: true)
                    }
                }

                // Quick replies (driver only)
                if isDriver {
                    quickReplyBar
                }

                Divider()

                // Input bar
                inputBar
            }
            .background(Color(hex: "F0F4F8").ignoresSafeArea())
            .navigationTitle(isDriver ? "Dispatch" : driverName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "2F80ED"))
                }
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 1) {
                        Text(isDriver ? "Dispatch Center" : driverName)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(hex: "2ECC71"))
                                .frame(width: 6, height: 6)
                            Text("Online")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Quick Reply Bar
    private var quickReplyBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(driverQuickReplies, id: \.self) { reply in
                    Button(action: { sendMessage(reply) }) {
                        Text(reply)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "2F80ED"))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color(hex: "2F80ED").opacity(0.1))
                                    .overlay(Capsule().strokeBorder(Color(hex: "2F80ED").opacity(0.3), lineWidth: 1))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color.white.opacity(0.8))
    }

    // MARK: - Input Bar
    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Message...", text: $inputText, axis: .vertical)
                .font(.system(size: 15, design: .rounded))
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color(hex: "E8EDF2"))
                )
                .focused($inputFocused)

            Button(action: { sendMessage(inputText) }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                     ? Color(hex: "C0C8D4")
                                     : Color(hex: "2F80ED"))
            }
            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.white)
    }

    // MARK: - Helpers
    private func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.send(text: trimmed, from: viewerRole, driverID: driverID)
        inputText = ""
        inputFocused = false
    }

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool) {
        guard let last = messages.last else { return }
        if animated {
            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
        } else {
            proxy.scrollTo(last.id, anchor: .bottom)
        }
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessage
    let viewerRole: MessageSender

    private var isOutgoing: Bool { message.sender == viewerRole }

    private var bubbleColor: Color {
        isOutgoing ? Color(hex: "2F80ED") : .white
    }
    private var textColor: Color {
        isOutgoing ? .white : Color(hex: "1A1A2E")
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            if isOutgoing { Spacer(minLength: 50) }

            if !isOutgoing {
                // Sender avatar
                ZStack {
                    Circle()
                        .fill(Color(hex: "2F80ED").opacity(0.15))
                        .frame(width: 30, height: 30)
                    Image(systemName: message.sender == .dispatch ? "antenna.radiowaves.left.and.right" : "steeringwheel")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "2F80ED"))
                }
            }

            VStack(alignment: isOutgoing ? .trailing : .leading, spacing: 3) {
                Text(message.text)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(textColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(bubbleColor)
                            .shadow(color: isOutgoing
                                    ? Color(hex: "2F80ED").opacity(0.25)
                                    : Color.black.opacity(0.06),
                                   radius: 4, y: 2)
                    )

                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }

            if !isOutgoing { Spacer(minLength: 50) }
        }
    }
}

#Preview {
    DriverDispatchChatView(
        driverID: Driver.sampleDrivers[0].id,
        driverName: Driver.sampleDrivers[0].name,
        viewerRole: .driver
    )
}
