import Foundation
import CryptoKit

// MARK: - NetworkSession
//
// Shared URLSession with certificate pinning.
// In DEBUG (simulator/local dev) pinning is skipped — the backend runs on
// plain HTTP localhost and there is no TLS certificate to pin.
// In production: replace pinnedPublicKeyHashes with the SHA-256 base64
// hash of your server's public key, generated with:
//   openssl s_client -connect yourserver.com:443 </dev/null \
//     | openssl x509 -pubkey -noout \
//     | openssl pkey -pubin -outform der \
//     | openssl dgst -sha256 -binary \
//     | base64

enum NetworkSession {
    static let pinned: URLSession = {
        let delegate = PinningDelegate()
        return URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
    }()
}

// MARK: - PinningDelegate

private final class PinningDelegate: NSObject, URLSessionDelegate {

    // SHA-256 base64 hashes of trusted server public keys.
    // Add backup pins (e.g. issuing CA) so a cert rotation doesn't lock users out.
    private let pinnedHashes: Set<String> = [
        "REPLACE_WITH_PRODUCTION_SERVER_PUBLIC_KEY_HASH",
        // "REPLACE_WITH_BACKUP_CA_PUBLIC_KEY_HASH",
    ]

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        #if DEBUG
        // Local HTTP server has no TLS — allow default handling in dev/simulator
        completionHandler(.performDefaultHandling, nil)
        return
        #else
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust
        else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Step 1 — validate the certificate chain
        var cfError: CFError?
        guard SecTrustEvaluateWithError(serverTrust, &cfError) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Step 2 — extract leaf certificate public key and hash it
        guard let leafCert   = SecTrustGetCertificateAtIndex(serverTrust, 0),
              let publicKey  = SecCertificateCopyKey(leafCert),
              let keyData    = SecKeyCopyExternalRepresentation(publicKey, nil) as Data?
        else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        let hashBase64 = Data(SHA256.hash(data: keyData)).base64EncodedString()

        // Step 3 — compare against pinned hashes
        if pinnedHashes.contains(hashBase64) {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            // Report MITM suspicion before rejecting
            SecurityMonitor.shared.report(
                .mitmDetected,
                context: [
                    "reason":        "certificate_pin_mismatch",
                    "received_hash": hashBase64,
                    "host":          challenge.protectionSpace.host,
                ]
            )
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
        #endif
    }
}
