import Foundation

public final class Secrets {
    let client: String
    let secret: String
    let googleLoginClientId: String
    let googleLoginSchemeId: String
    let googleLoginServerClientId: String
    let zendeskAppId: String
    let zendeskUrl: String
    let zendeskClientId: String
    let tenorApiKey: String
    let sentryDSN: String
    let encryptedLogKey: String
    let debuggingKey: String
    let docsBotId: String

    /// - warning: This need to be set as earliest as possible during the app runtime.
    public static var current = Secrets(client: "", secret: "", googleLoginClientId: "", googleLoginSchemeId: "", googleLoginServerClientId: "", zendeskAppId: "", zendeskUrl: "", zendeskClientId: "", tenorApiKey: "", sentryDSN: "", encryptedLogKey: "", debuggingKey: "", docsBotId: "")

    public init(client: String, secret: String, googleLoginClientId: String, googleLoginSchemeId: String, googleLoginServerClientId: String, zendeskAppId: String, zendeskUrl: String, zendeskClientId: String, tenorApiKey: String, sentryDSN: String, encryptedLogKey: String, debuggingKey: String, docsBotId: String) {
        self.client = client
        self.secret = secret
        self.googleLoginClientId = googleLoginClientId
        self.googleLoginSchemeId = googleLoginSchemeId
        self.googleLoginServerClientId = googleLoginServerClientId
        self.zendeskAppId = zendeskAppId
        self.zendeskUrl = zendeskUrl
        self.zendeskClientId = zendeskClientId
        self.tenorApiKey = tenorApiKey
        self.sentryDSN = sentryDSN
        self.encryptedLogKey = encryptedLogKey
        self.debuggingKey = debuggingKey
        self.docsBotId = docsBotId
    }
}
