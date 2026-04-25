import Foundation
import UIKit

// MARK: - JailbreakDetector
//
// Runs on app launch to detect common jailbreak indicators.
// On a real jailbroken device these checks are bypassable via
// Substrate hooks — layered defense is needed in production.
// For portfolio: demonstrates mobile security awareness.

struct JailbreakDetector {

    // Paths that only exist on jailbroken devices
    private static let suspiciousPaths: [String] = [
        "/Applications/Cydia.app",
        "/Applications/Sileo.app",
        "/Applications/Zebra.app",
        "/Library/MobileSubstrate/MobileSubstrate.dylib",
        "/bin/bash",
        "/usr/sbin/sshd",
        "/etc/apt",
        "/usr/bin/ssh",
        "/private/var/lib/apt",
        "/private/var/mobile/Library/SBSettings/Themes",
    ]

    // Returns true if any jailbreak indicator is detected
    static func isJailbroken() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return pathsExist() || canWriteOutsideSandbox() || suspiciousURLScheme()
        #endif
    }

    // MARK: - Checks

    private static func pathsExist() -> Bool {
        let fm = FileManager.default
        return suspiciousPaths.contains { fm.fileExists(atPath: $0) }
    }

    private static func canWriteOutsideSandbox() -> Bool {
        // A sandboxed app cannot write to /private — jailbroken ones can
        let testPath = "/private/jb_test_\(UUID().uuidString)"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try? FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {
            return false
        }
    }

    private static func suspiciousURLScheme() -> Bool {
        // Cydia registers a custom URL scheme
        guard let url = URL(string: "cydia://") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    // MARK: - Report

    static func checkAndReport() {
        guard isJailbroken() else { return }

        let indicators = buildIndicatorList()
        SecurityMonitor.shared.report(
            .jailbreakDetected,
            context: [
                "indicators": indicators.joined(separator: ", "),
                "os_version": UIDevice.current.systemVersion,
                "model":      UIDevice.current.model,
            ]
        )
    }

    private static func buildIndicatorList() -> [String] {
        var found: [String] = []
        let fm = FileManager.default
        for path in suspiciousPaths where fm.fileExists(atPath: path) {
            found.append(path)
        }
        if canWriteOutsideSandbox() { found.append("sandbox_escape") }
        if suspiciousURLScheme()    { found.append("cydia_url_scheme") }
        return found
    }
}
