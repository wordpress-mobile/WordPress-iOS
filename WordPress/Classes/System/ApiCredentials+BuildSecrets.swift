import BuildSettingsKit

extension ApiCredentials {

    static func toSecrets() -> BuildSecrets {
        BuildSecrets(
            oauth: .init(client: client, secret: secret),
            zendesk: .init(
                appId: zendeskAppId,
                url: zendeskUrl,
                clientId: zendeskClientId
            ),
            sentryDSN: sentryDSN,
            docsBotId: docsBotId,
            encryptedLogsKey: encryptedLogKey,
            debuggingKey: debuggingKey
        )
    }
}
