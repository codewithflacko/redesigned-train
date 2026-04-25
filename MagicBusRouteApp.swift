import SwiftUI

@main
struct MagicBusRouteApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            WelcomeView()
                .environmentObject(AppState.shared)
                .privacyOverlay()
                .sessionTimeout()
                .overlay { BiometricLockOverlay() }
                .onAppear {
                    NotificationManager.shared.requestPermission()
                    JailbreakDetector.checkAndReport()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        BiometricLockManager.shared.lockIfAuthenticated()
                    }
                }
        }
    }
}
