import CryptoKit
import Foundation
import Testing

@testable import WordPress

/// End-to-end encode/decode of the sealed session payload.
struct DebugSessionTransferCryptoTests {
    private func makeReceiverKey() -> Curve25519.KeyAgreement.PrivateKey {
        Curve25519.KeyAgreement.PrivateKey()
    }

    @Test func sealThenOpenReturnsTheOriginalSession() throws {
        let receiver = makeReceiverKey()
        let session = DebugWordPressComSession(token: "bearer-abc-123", username: "jeremy")

        let envelope = try DebugSessionTransferCrypto.seal(session, to: receiver.publicKey.rawRepresentation)
        let opened = try DebugSessionTransferCrypto.open(envelope, with: receiver)

        #expect(opened == session)
    }

    @Test func sealThenOpenRoundTripsWithoutAUsername() throws {
        let receiver = makeReceiverKey()
        let session = DebugWordPressComSession(token: "bearer-xyz", username: nil)

        let envelope = try DebugSessionTransferCrypto.seal(session, to: receiver.publicKey.rawRepresentation)
        #expect(try DebugSessionTransferCrypto.open(envelope, with: receiver) == session)
    }

    @Test func openingWithTheWrongKeyFails() throws {
        let receiver = makeReceiverKey()
        let envelope = try DebugSessionTransferCrypto.seal(
            DebugWordPressComSession(token: "secret", username: nil),
            to: receiver.publicKey.rawRepresentation
        )

        let attacker = makeReceiverKey()
        #expect(throws: (any Error).self) {
            try DebugSessionTransferCrypto.open(envelope, with: attacker)
        }
    }

    @Test func tamperingWithTheCiphertextFails() throws {
        let receiver = makeReceiverKey()
        let envelope = try DebugSessionTransferCrypto.seal(
            DebugWordPressComSession(token: "secret", username: nil),
            to: receiver.publicKey.rawRepresentation
        )

        var corrupted = envelope.ciphertext
        corrupted[corrupted.index(before: corrupted.endIndex)] ^= 0x01
        let tampered = DebugSessionEnvelope(ephemeralPublicKey: envelope.ephemeralPublicKey, ciphertext: corrupted)

        #expect(throws: (any Error).self) {
            try DebugSessionTransferCrypto.open(tampered, with: receiver)
        }
    }

    @Test func envelopeEncodesAndDecodesAsJSON() throws {
        let envelope = DebugSessionEnvelope(
            ephemeralPublicKey: Data([0x01, 0x02, 0x03]),
            ciphertext: Data([0xAA, 0xBB, 0xCC])
        )
        let data = try JSONEncoder().encode(envelope)
        #expect(try JSONDecoder().decode(DebugSessionEnvelope.self, from: data) == envelope)
    }

    @Test func publicKeyEncodingIsURLSafeAndReversible() {
        let key = makeReceiverKey().publicKey.rawRepresentation
        let encoded = DebugSessionTransferCrypto.encodePublicKey(key)

        #expect(!encoded.contains("+"))
        #expect(!encoded.contains("/"))
        #expect(!encoded.contains("="))
        #expect(DebugSessionTransferCrypto.decodePublicKey(encoded) == key)
    }

    @Test func decodingAMalformedPublicKeyReturnsNil() {
        #expect(DebugSessionTransferCrypto.decodePublicKey("!! not base64 !!") == nil)
    }

    @Test func intentEncodesAndDecodesAsJSON() throws {
        let intent = DebugSessionTransferIntent(protocolVersion: "2")
        let data = try JSONEncoder().encode(intent)
        #expect(try JSONDecoder().decode(DebugSessionTransferIntent.self, from: data) == intent)
    }
}

/// Encode/decode of the Bonjour advertisement record.
struct DebugSessionReceiverInfoTests {
    private func makeInfo() -> DebugSessionReceiverInfo {
        DebugSessionReceiverInfo(
            protocolVersion: "2",
            name: "media-test",
            model: "iPhone 15 Pro",
            isSimulator: true,
            app: "jetpack",
            isSignedIn: false
        )
    }

    @Test func txtDictionaryRoundTrips() {
        let info = makeInfo()
        #expect(DebugSessionReceiverInfo(txtDictionary: info.txtDictionary) == info)
    }

    @Test func txtDictionaryCarriesNoKeyMaterial() {
        // The receiver's public key must never be advertised — it lives only in the on-screen QR.
        #expect(!makeInfo().txtDictionary.keys.contains("pk"))
    }

    @Test func parsingFailsWithoutAVersion() {
        var txt = makeInfo().txtDictionary
        txt.removeValue(forKey: DebugSessionReceiverInfo.Key.version)
        #expect(DebugSessionReceiverInfo(txtDictionary: txt) == nil)
    }

    @Test func platformAndSignedInDecodeToBooleans() throws {
        let info = try #require(
            DebugSessionReceiverInfo(txtDictionary: [
                DebugSessionReceiverInfo.Key.version: "2",
                DebugSessionReceiverInfo.Key.platform: "device",
                DebugSessionReceiverInfo.Key.signedIn: "1"
            ])
        )
        #expect(info.isSimulator == false)
        #expect(info.isSignedIn == true)
    }
}
