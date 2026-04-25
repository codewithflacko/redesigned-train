import Foundation
import LocalAuthentication
import SwiftUI

// MARK: - BiometricLockManager
//
// Locks the app whenever it returns from the background (if authenticated).
// Requires FaceID/TouchID to re-enter. Falls back to device passcode.

@MainActor
final class BiometricLockManager: ObservableObject {
    static let shared = BiometricLockManager()
    private init() {}

    @Published private(set) var isLocked: Bool = false
    @Published private(set) var authError: String? = nil

    // Called when scenePhase transitions background → active
    func lockIfAuthenticated() {
        #if targetEnvironment(simulator)
        return  // Skip biometric lock in simulator
        #endif
        guard AuthManager.shared.isAuthenticated else { return }
        isLocked = true
        authError = nil
    }

    func authenticate() {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            // Device has no biometric or passcode — unlock automatically
            isLocked = false
            return
        }

        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "Confirm it's you to access MagicBusRoute"
        ) { success, evalError in
            DispatchQueue.main.async {
                if success {
                    self.isLocked = false
                    self.authError = nil
                } else {
                    self.authError = evalError?.localizedDescription ?? "Authentication failed."
                }
            }
        }
    }
}

// MARK: - BiometricLockOverlay

struct BiometricLockOverlay: View {
    @ObservedObject private var lockManager = BiometricLockManager.shared

    var body: some View {
        if lockManager.isLocked {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 24) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.white.opacity(0.8))

                    Text("MagicBusRoute is locked")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    if let error = lockManager.authError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Button {
                        lockManager.authenticate()
                    } label: {
                        Label("Unlock", systemImage: "faceid")
                            .font(.headline)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(.white.opacity(0.15))
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
            }
            .onAppear { lockManager.authenticate() }
        }
    }
}
