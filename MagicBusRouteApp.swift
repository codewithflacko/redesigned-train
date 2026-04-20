import SwiftUI

@main
struct MagicBusRouteApp: App {
    var body: some Scene {
        WindowGroup {
            WelcomeView()
                .environmentObject(AppState.shared)
                .onAppear {
                    NotificationManager.shared.requestPermission()
                }
        }
    }
}
