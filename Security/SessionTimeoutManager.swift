import SwiftUI
import Combine

// MARK: - SessionTimeoutManager
//
// Auto-logs out after 30 minutes of inactivity.
// Call resetActivity() on any meaningful user interaction.
// A timer checks every 60 seconds — lightweight, no busy-polling.

@MainActor
final class SessionTimeoutManager: ObservableObject {
    static let shared = SessionTimeoutManager()
    private init() {}

    @Published private(set) var sessionExpired: Bool = false

    private let timeoutInterval: TimeInterval = 30 * 60  // 30 minutes
    private var lastActivity: Date = Date()
    private var timer: AnyCancellable?

    // MARK: - Lifecycle

    func start() {
        lastActivity = Date()
        sessionExpired = false
        timer = Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.checkTimeout() }
    }

    func stop() {
        timer?.cancel()
        timer = nil
        sessionExpired = false
    }

    func resetActivity() {
        lastActivity = Date()
        sessionExpired = false
    }

    // MARK: - Private

    private func checkTimeout() {
        guard AuthManager.shared.isAuthenticated else { stop(); return }
        if Date().timeIntervalSince(lastActivity) >= timeoutInterval {
            sessionExpired = true
            AuthManager.shared.logout()
            stop()
        }
    }
}

// MARK: - SessionTimeoutModifier
//
// Apply at the root view. Any touch anywhere resets the idle timer.
// Uses simultaneousGesture so it never blocks child interactions.

private struct SessionTimeoutModifier: ViewModifier {
    @ObservedObject private var manager = SessionTimeoutManager.shared
    @ObservedObject private var auth    = AuthManager.shared

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in SessionTimeoutManager.shared.resetActivity() }
            )
            .onChange(of: auth.isAuthenticated) { _, isAuth in
                isAuth ? SessionTimeoutManager.shared.start()
                       : SessionTimeoutManager.shared.stop()
            }
            .overlay {
                if manager.sessionExpired {
                    SessionExpiredBanner()
                }
            }
    }
}

extension View {
    func sessionTimeout() -> some View {
        modifier(SessionTimeoutModifier())
    }
}

// MARK: - SessionExpiredBanner

private struct SessionExpiredBanner: View {
    @State private var visible = true

    var body: some View {
        if visible {
            VStack {
                HStack(spacing: 10) {
                    Image(systemName: "clock.badge.exclamationmark.fill")
                        .foregroundStyle(.yellow)
                    Text("Session expired — please sign in again.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        visible = false
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .padding(.top, 60)

                Spacer()
            }
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
