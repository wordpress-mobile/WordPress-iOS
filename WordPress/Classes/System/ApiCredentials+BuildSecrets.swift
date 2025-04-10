import BuildSettingsKit

extension ApiCredentials {

    static func toSecrets() -> BuildSecrets {
        BuildSecrets(
            oauth: .init(client: client, secret: secret),
            google: .init(
                clientId: googleLoginClientId,
                schemeId: googleLoginSchemeId,
                serverClientId: googleLoginServerClientId
            ),
            zendesk: .init(
                appId: zendeskAppId,
                url: zendeskUrl,
                clientId: zendeskClientId
            ),
            tenorApiKey: tenorApiKey,
            sentryDSN: sentryDSN,
            docsBotId: docsBotId,
            encryptedLogsKey: encryptedLogKey,
            debuggingKey: debuggingKey
        )
    }
}
