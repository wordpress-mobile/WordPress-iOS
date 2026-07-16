import Foundation

/// The metadata a receiver advertises in its Bonjour TXT record, and which a sender parses back to
/// populate its discovery list. Round-trips through the TXT key-value dictionary (`txtDictionary` /
/// `init?(txtDictionary:)`), so the receiver and the browser share one definition.
///
/// Deliberately carries **no key material** — the receiver's public key is shown only in its QR, on
/// its own screen, and never travels the network. That's what makes an impostor receiver useless:
/// the sender seals to the key it read off the physical screen, so a spoofed advertisement (the name
/// here is attacker-controllable) can't get the token. See the security note on
/// `DebugSessionTransferReceiver`.
struct DebugSessionReceiverInfo: Equatable {
    var protocolVersion: String
    var name: String
    var model: String
    var isSimulator: Bool
    var app: String
    var isSignedIn: Bool

    enum Key {
        static let version = "v"
        static let name = "name"
        static let model = "model"
        static let platform = "platform"
        static let app = "app"
        static let signedIn = "signedIn"
    }

    var txtDictionary: [String: String] {
        [
            Key.version: protocolVersion,
            Key.name: name,
            Key.model: model,
            Key.platform: isSimulator ? "simulator" : "device",
            Key.app: app,
            Key.signedIn: isSignedIn ? "1" : "0"
        ]
    }

    init(
        protocolVersion: String,
        name: String,
        model: String,
        isSimulator: Bool,
        app: String,
        isSignedIn: Bool
    ) {
        self.protocolVersion = protocolVersion
        self.name = name
        self.model = model
        self.isSimulator = isSimulator
        self.app = app
        self.isSignedIn = isSignedIn
    }

    /// Parses a receiver's advertised TXT record. Returns `nil` when the protocol version — the one
    /// field a sender needs in order to know it can talk to this receiver — is missing.
    init?(txtDictionary txt: [String: String]) {
        guard let protocolVersion = txt[Key.version] else {
            return nil
        }
        self.protocolVersion = protocolVersion
        self.name = txt[Key.name] ?? ""
        self.model = txt[Key.model] ?? ""
        self.isSimulator = txt[Key.platform] == "simulator"
        self.app = txt[Key.app] ?? ""
        self.isSignedIn = txt[Key.signedIn] == "1"
    }
}
