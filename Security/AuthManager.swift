import Foundation
import Security

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case invalidCredentials
    case roleMismatch
    case accountLocked(minutesRemaining: Int)
    case networkError(String)
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:              return "Incorrect email or password."
        case .roleMismatch:                    return "These credentials don't match this portal."
        case .accountLocked(let mins):         return "Account locked. Try again in \(mins) minute\(mins == 1 ? "" : "s")."
        case .networkError(let msg):           return "Connection error: \(msg)"
        case .serverError(let code):           return "Server error (\(code)). Try again."
        }
    }
}

// MARK: - AuthManager
//
// Handles JWT-based authentication for all four portals.
// Stores the token in the iOS Keychain (never UserDefaults).
//
// Usage:
//   let success = try await AuthManager.shared.login(email:password:role:)
//   AuthManager.shared.logout()

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()
    private init() { loadFromKeychain() }

    // ---------------------------------------------------------------------------
    // Published state (drives UI)
    // ---------------------------------------------------------------------------

    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var currentRole: UserRole? = nil
    @Published private(set) var userId: String? = nil
    @Published private(set) var requiresOTP: Bool = false
    @Published private(set) var accessLevel: String = "full"

    private(set) var accessToken: String? = nil
    private(set) var pendingOTPSession: String? = nil
    private(set) var pendingEmail: String? = nil
    private(set) var pendingRole: UserRole? = nil

    // ---------------------------------------------------------------------------
    // Config
    // ---------------------------------------------------------------------------

    private let baseURL = "http://127.0.0.1:8000"
    private let keychainService = "com.magicbusroute.auth"
    private let keychainAccount = "access_token"

    // ---------------------------------------------------------------------------
    // Login
    // ---------------------------------------------------------------------------

    func login(email: String, password: String, role: UserRole) async throws {
        guard let url = URL(string: "\(baseURL)/auth/login") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = LoginRequestPayload(email: email, password: password, role: role.rawValue)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await NetworkSession.pinned.data(for: request)
        } catch {
            SecurityMonitor.shared.reportFailedLogin(email: email, role: role)
            throw AuthError.networkError(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AuthError.networkError("Invalid response")
        }

        switch http.statusCode {
        case 200:
            let loginResponse = try JSONDecoder().decode(LoginResponsePayload.self, from: data)

            if loginResponse.requires_otp, let session = loginResponse.otp_session {
                // Step 1 complete — store pending state, wait for OTP
                pendingOTPSession = session
                pendingEmail      = email
                pendingRole       = role
                requiresOTP       = true
                // Return demo code via thrown value piggyback — callers read AuthManager.demoOTPCode
                demoOTPCode = loginResponse.demo_code
                return
            }

            // Admin path — JWT returned directly (no OTP)
            if let token = loginResponse.access_token,
               let uid   = loginResponse.user_id {
                persist(token: token, userId: uid, role: role, accessLevel: "full")
                SecurityMonitor.shared.reportSuccessfulLogin(userId: uid, role: role)
            }

        case 401:
            SecurityMonitor.shared.reportFailedLogin(email: email, role: role)
            // Distinguish role mismatch from bad credentials based on server message
            if let body = try? JSONDecoder().decode([String: String].self, from: data),
               body["detail"]?.contains("role") == true {
                throw AuthError.roleMismatch
            }
            throw AuthError.invalidCredentials

        case 429:
            // Account is locked — parse minutes remaining from server message
            let mins: Int
            if let body = try? JSONDecoder().decode([String: String].self, from: data),
               let detail = body["detail"],
               let extracted = detail.split(separator: " ").compactMap({ Int($0) }).first {
                mins = extracted
            } else {
                mins = 15
            }
            throw AuthError.accountLocked(minutesRemaining: mins)

        default:
            SecurityMonitor.shared.reportFailedLogin(email: email, role: role)
            throw AuthError.serverError(http.statusCode)
        }
    }

    // ---------------------------------------------------------------------------
    // OTP verification
    // ---------------------------------------------------------------------------

    @Published private(set) var demoOTPCode: String? = nil

    func verifyOTP(code: String) async throws {
        guard let session = pendingOTPSession,
              let email   = pendingEmail,
              let role    = pendingRole else {
            throw AuthError.networkError("No pending OTP session.")
        }

        guard let url = URL(string: "\(baseURL)/auth/otp/verify") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["otp_session": session, "code": code]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await NetworkSession.pinned.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AuthError.networkError("Invalid response")
        }

        switch http.statusCode {
        case 200:
            let loginResponse = try JSONDecoder().decode(LoginResponsePayload.self, from: data)
            guard let token = loginResponse.access_token, let uid = loginResponse.user_id else {
                throw AuthError.networkError("Missing token in response")
            }
            clearOTPState()
            persist(token: token, userId: uid, role: role, accessLevel: loginResponse.role == "view_only" ? "view_only" : "full")
            SecurityMonitor.shared.reportSuccessfulLogin(userId: uid, role: role)
            SecurityMonitor.shared.report(.otpVerified, userId: uid, role: role)
        case 401:
            throw AuthError.invalidCredentials
        default:
            throw AuthError.serverError(http.statusCode)
        }
    }

    func clearOTPState() {
        requiresOTP       = false
        pendingOTPSession = nil
        pendingEmail      = nil
        pendingRole       = nil
        demoOTPCode       = nil
    }

    func acceptInviteLogin(token: String, userId: String, email: String) {
        // Decode access level from JWT without a library
        if let level = decodeAccessLevel(from: token) {
            persist(token: token, userId: userId, role: .parent, accessLevel: level)
        } else {
            persist(token: token, userId: userId, role: .parent, accessLevel: "view_only")
        }
    }

    private func decodeAccessLevel(from token: String) -> String? {
        let parts = token.split(separator: ".").map(String.init)
        guard parts.count == 3 else { return nil }
        var base64 = parts[1]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64 += "=" }
        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return json["access_level"] as? String
    }

    // ---------------------------------------------------------------------------
    // Logout
    // ---------------------------------------------------------------------------

    func logout() {
        let tokenToSend = accessToken
        clearOTPState()
        clearKeychain()
        accessToken     = nil
        currentRole     = nil
        userId          = nil
        accessLevel     = "full"
        isAuthenticated = false

        // Notify backend (fire-and-forget)
        Task {
            guard let url   = URL(string: "\(baseURL)/auth/logout"),
                  let token = tokenToSend else { return }
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            _ = try? await NetworkSession.pinned.data(for: req)
        }
    }

    // ---------------------------------------------------------------------------
    // Keychain helpers
    // ---------------------------------------------------------------------------

    private func persist(token: String, userId: String, role: UserRole, accessLevel: String = "full") {
        accessToken        = token
        self.userId        = userId
        currentRole        = role
        self.accessLevel   = accessLevel
        isAuthenticated    = true
        saveToKeychain(token: token)
    }

    private func saveToKeychain(token: String) {
        guard let data = token.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String:   data,
        ]
        SecItemDelete(query as CFDictionary)   // remove stale token first
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let token = String(data: data, encoding: .utf8)
        else { return }

        guard !isTokenExpired(token) else {
            clearKeychain()  // remove the stale token
            return
        }

        accessToken     = token
        isAuthenticated = true
    }

    /// Decode the JWT payload and check the `exp` claim without a third-party library.
    private func isTokenExpired(_ token: String) -> Bool {
        let parts = token.split(separator: ".").map(String.init)
        guard parts.count == 3 else { return true }

        // JWT uses base64url — convert to standard base64 and pad
        var base64 = parts[1]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64 += "=" }

        guard let payloadData = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let exp = json["exp"] as? TimeInterval
        else { return true }

        return Date().timeIntervalSince1970 >= exp
    }

    private func clearKeychain() {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
