import SwiftUI

@main
struct MagicBusRouteApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ZStack {
                WelcomeView()
                    .environmentObject(AppState.shared)
                    .privacyOverlay()
                    .sessionTimeout()
                    .overlay { BiometricLockOverlay() }
                    .onAppear {
                        NotificationManager.shared.requestPermission()
                        JailbreakDetector.checkAndReport()
                        AfterHoursManager.shared.startMonitoring()
                    }
                    .onChange(of: scenePhase) { _, newPhase in
                        if newPhase == .active {
                            BiometricLockManager.shared.lockIfAuthenticated()
                        }
                    }

                AfterHoursView()
            }
        }
    }
}
