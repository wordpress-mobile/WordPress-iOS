import Foundation

/// The metadata a receiver advertises in its Bonjour TXT record, and which a sender parses back to
/// populate its discovery list. Round-trips through the TXT key-value dictionary (`txtDictionary` /
/// `init?(txtDictionary:)`), so the receiver and the (future) browser share one definition.
struct DebugSessionReceiverInfo: Equatable {
    var protocolVersion: String
    var name: String
    var model: String
    var isSimulator: Bool
    var app: String
    var isSignedIn: Bool
    var publicKey: Data

    enum Key {
        static let version = "v"
        static let name = "name"
        static let model = "model"
        static let platform = "platform"
        static let app = "app"
        static let signedIn = "signedIn"
        static let publicKey = "pk"
    }

    var txtDictionary: [String: String] {
        [
            Key.version: protocolVersion,
            Key.name: name,
            Key.model: model,
            Key.platform: isSimulator ? "simulator" : "device",
            Key.app: app,
            Key.signedIn: isSignedIn ? "1" : "0",
            Key.publicKey: DebugSessionTransferCrypto.encodePublicKey(publicKey)
        ]
    }

    init(
        protocolVersion: String,
        name: String,
        model: String,
        isSimulator: Bool,
        app: String,
        isSignedIn: Bool,
        publicKey: Data
    ) {
        self.protocolVersion = protocolVersion
        self.name = name
        self.model = model
        self.isSimulator = isSimulator
        self.app = app
        self.isSignedIn = isSignedIn
        self.publicKey = publicKey
    }

    /// Parses a receiver's advertised TXT record. Returns `nil` when the public key — the one field
    /// a sender can't proceed without — is missing or malformed.
    init?(txtDictionary txt: [String: String]) {
        guard let publicKeyToken = txt[Key.publicKey],
            let publicKey = DebugSessionTransferCrypto.decodePublicKey(publicKeyToken)
        else {
            return nil
        }
        self.publicKey = publicKey
        self.protocolVersion = txt[Key.version] ?? ""
        self.name = txt[Key.name] ?? ""
        self.model = txt[Key.model] ?? ""
        self.isSimulator = txt[Key.platform] == "simulator"
        self.app = txt[Key.app] ?? ""
        self.isSignedIn = txt[Key.signedIn] == "1"
    }
}
