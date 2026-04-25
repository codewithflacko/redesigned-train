import SwiftUI

// MARK: - PrivacyOverlay
//
// Covers the screen with a blurred black overlay whenever the app
// moves to the background. Prevents sensitive content from appearing
// in the iOS app switcher screenshot or being captured on screen recording.

private struct PrivacyOverlayModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content.overlay {
            if scenePhase != .active {
                Color.black
                    .ignoresSafeArea()
                    .overlay {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.white.opacity(0.6))
                    }
            }
        }
    }
}

extension View {
    func privacyOverlay() -> some View {
        modifier(PrivacyOverlayModifier())
    }
}
