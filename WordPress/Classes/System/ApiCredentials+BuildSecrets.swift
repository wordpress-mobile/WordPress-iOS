import BuildSettingsKit

extension ApiCredentials {

    static func toSecrets() -> BuildSecrets {
        BuildSecrets(
            oauth: .init(client: client, secret: secret),
            encryptedLogsKey: encryptedLogKey,
            debuggingKey: debuggingKey
        )
    }
}
