public struct BuildSecrets: Sendable {

    public struct OAuth: Sendable {
        public let client: String
        public let secret: String

        public init(client: String, secret: String) {
            self.client = client
            self.secret = secret
        }
    }

    public struct Zendesk: Sendable {
        public let appId: String
        public let url: String
        public let clientId: String

        public init(appId: String, url: String, clientId: String) {
            self.appId = appId
            self.url = url
            self.clientId = clientId
        }
    }

    public let oauth: OAuth
    public let zendesk: Zendesk
    public let encryptedLogsKey: String
    public let debuggingKey: String

    public init(
        oauth: OAuth,
        zendesk: Zendesk,
        encryptedLogsKey: String,
        debuggingKey: String
    ) {
        self.oauth = oauth
        self.zendesk = zendesk
        self.encryptedLogsKey = encryptedLogsKey
        self.debuggingKey = debuggingKey
    }
}

extension BuildSecrets {

    public static let dummy = BuildSecrets(
        oauth: .init(client: "", secret: ""),
        zendesk: .init(appId: "", url: "", clientId: ""),
        encryptedLogsKey: "",
        debuggingKey: ""
    )
}

extension BuildSecrets {

    nonisolated(unsafe) static var configuredSecrets: BuildSecrets?

    static var current: BuildSecrets {
        switch BuildSettingsEnvironment.current {
        case .preview:
            return .dummy
        case .test:
            // TODO: Should we crash if a secret is accessed from the tests to prevent under-the-hood access and favor injection?
            return .dummy
        case .live:
            guard let secrets = configuredSecrets else {
                fatalError("Attempted to access BuildSettings before configuring secrets.")
            }

            return secrets
        }
    }
}
