import CryptoKit
import Foundation

/// Plaintext WordPress.com session that is encrypted before it crosses the network.
///
/// The token alone is enough to sign in — `username` is carried purely so the receiver can show
/// "Signing in as …" before the account details come back from the API.
struct DebugWordPressComSession: Codable, Equatable {
    let token: String
    var username: String?
}

/// Encrypted wire envelope: the sender's ephemeral public key plus the AES-GCM–sealed session.
/// Encoded as JSON, where `Data` fields serialize to base64.
struct DebugSessionEnvelope: Codable, Equatable {
    let ephemeralPublicKey: Data
    let ciphertext: Data
}

/// First message the sender sends: "I have a WordPress.com session to share." It carries only the
/// protocol version — deliberately *no* key material. It's what triggers the receiver to mint a
/// fresh key and show its QR; the receiver's real public key never travels the network, only the
/// on-screen QR (see the security note on `DebugSessionTransferReceiver`).
struct DebugSessionTransferIntent: Codable, Equatable {
    let protocolVersion: String
}

/// Seals a WordPress.com session to the receiver's per-transfer X25519 public key — the one it shows
/// in its QR — so the token, a full-access bearer credential, is never readable in flight even over
/// plaintext TCP on a shared network. Only the receiver, holding the matching private key, can open
/// the envelope.
///
/// Scheme: ephemeral-static ECDH (X25519) → HKDF-SHA256 → AES-GCM. The sender's per-message
/// ephemeral key gives forward secrecy; the AES-GCM tag makes tampering detectable.
///
/// This is the *confidentiality* half of the design (it defeats a passive sniffer). The *authenticity*
/// half — that the sender sealed to the genuine receiver and not an impostor — comes from the key
/// being read off the receiver's screen rather than the network (see `DebugSessionTransferReceiver`).
enum DebugSessionTransferCrypto {
    enum Failure: Error { case sealingFailed }

    private static let salt = Data("org.wordpress.debug-session-transfer".utf8)

    static func seal(_ session: DebugWordPressComSession, to receiverPublicKey: Data) throws -> DebugSessionEnvelope {
        let recipient = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: receiverPublicKey)
        let ephemeral = Curve25519.KeyAgreement.PrivateKey()
        let secret = try ephemeral.sharedSecretFromKeyAgreement(with: recipient)
        let key = symmetricKey(
            from: secret,
            ephemeralPublicKey: ephemeral.publicKey.rawRepresentation,
            receiverPublicKey: receiverPublicKey
        )
        let sealedBox = try AES.GCM.seal(JSONEncoder().encode(session), using: key)
        guard let combined = sealedBox.combined else {
            throw Failure.sealingFailed
        }
        return DebugSessionEnvelope(ephemeralPublicKey: ephemeral.publicKey.rawRepresentation, ciphertext: combined)
    }

    static func open(
        _ envelope: DebugSessionEnvelope,
        with privateKey: Curve25519.KeyAgreement.PrivateKey
    ) throws -> DebugWordPressComSession {
        let ephemeral = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: envelope.ephemeralPublicKey)
        let secret = try privateKey.sharedSecretFromKeyAgreement(with: ephemeral)
        let key = symmetricKey(
            from: secret,
            ephemeralPublicKey: envelope.ephemeralPublicKey,
            receiverPublicKey: privateKey.publicKey.rawRepresentation
        )
        let plaintext = try AES.GCM.open(AES.GCM.SealedBox(combined: envelope.ciphertext), using: key)
        return try JSONDecoder().decode(DebugWordPressComSession.self, from: plaintext)
    }

    private static func symmetricKey(
        from secret: SharedSecret,
        ephemeralPublicKey: Data,
        receiverPublicKey: Data
    ) -> SymmetricKey {
        secret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: salt,
            sharedInfo: ephemeralPublicKey + receiverPublicKey,
            outputByteCount: 32
        )
    }

    /// URL-safe (base64url, unpadded) encoding of the receiver's public key, for the QR it shows.
    static func encodePublicKey(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    static func decodePublicKey(_ string: String) -> Data? {
        var base64 = string.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64 += "=" }
        return Data(base64Encoded: base64)
    }
}
