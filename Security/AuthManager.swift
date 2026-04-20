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

    // Token is internal — only SecurityMonitor and network calls need it
    private(set) var accessToken: String? = nil

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
            (data, response) = try await URLSession.shared.data(for: request)
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
            persist(token: loginResponse.access_token, userId: loginResponse.user_id, role: role)
            SecurityMonitor.shared.reportSuccessfulLogin(userId: loginResponse.user_id, role: role)

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
    // Logout
    // ---------------------------------------------------------------------------

    func logout() {
        let tokenToSend = accessToken  // capture before clearing

        clearKeychain()
        accessToken    = nil
        currentRole    = nil
        userId         = nil
        isAuthenticated = false

        // Notify backend (fire-and-forget)
        Task {
            guard let url   = URL(string: "\(baseURL)/auth/logout"),
                  let token = tokenToSend else { return }
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            _ = try? await URLSession.shared.data(for: req)
        }
    }

    // ---------------------------------------------------------------------------
    // Keychain helpers
    // ---------------------------------------------------------------------------

    private func persist(token: String, userId: String, role: UserRole) {
        accessToken     = token
        self.userId     = userId
        currentRole     = role
        isAuthenticated = true
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
