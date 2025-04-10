public struct BuildSecrets: Sendable {

    public struct OAuth: Sendable {
        public let client: String
        public let secret: String

        public init(client: String, secret: String) {
            self.client = client
            self.secret = secret
        }
    }

    public struct Google: Sendable {
        public let clientId: String
        public let schemeId: String
        public let serverClientId: String

        public init(clientId: String, schemeId: String, serverClientId: String) {
            self.clientId = clientId
            self.schemeId = schemeId
            self.serverClientId = serverClientId
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
    public let google: Google
    public let zendesk: Zendesk
    public let tenorApiKey: String
    public let sentryDSN: String
    public let docsBotId: String
    public let encryptedLogsKey: String
    public let debuggingKey: String

    public init(
        oauth: OAuth,
        google: Google,
        zendesk: Zendesk,
        tenorApiKey: String,
        sentryDSN: String,
        docsBotId: String,
        encryptedLogsKey: String,
        debuggingKey: String
    ) {
        self.oauth = oauth
        self.google = google
        self.zendesk = zendesk
        self.tenorApiKey = tenorApiKey
        self.sentryDSN = sentryDSN
        self.docsBotId = docsBotId
        self.encryptedLogsKey = encryptedLogsKey
        self.debuggingKey = debuggingKey
    }
}

extension BuildSecrets {

    public static let dummy: BuildSecrets = BuildSecrets(
        oauth: .init(client: "", secret: ""),
        google: .init(clientId: "", schemeId: "", serverClientId: ""),
        zendesk: .init(appId: "", url: "", clientId: ""),
        tenorApiKey: "",
        sentryDSN: "",
        docsBotId: "",
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
