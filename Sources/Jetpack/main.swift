import UIKit

Secrets.current = Secrets(
    client: ApiCredentials.client,
    secret: ApiCredentials.secret,
    googleLoginClientId: ApiCredentials.googleLoginClientId,
    googleLoginSchemeId: ApiCredentials.googleLoginSchemeId,
    googleLoginServerClientId: ApiCredentials.googleLoginServerClientId,
    zendeskAppId: ApiCredentials.zendeskAppId,
    zendeskUrl: ApiCredentials.zendeskUrl,
    zendeskClientId: ApiCredentials.zendeskClientId,
    tenorApiKey: ApiCredentials.tenorApiKey,
    sentryDSN: ApiCredentials.sentryDSN,
    encryptedLogKey: ApiCredentials.encryptedLogKey,
    debuggingKey: ApiCredentials.debuggingKey,
    docsBotId: ApiCredentials.docsBotId
)

UIApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv,
    nil,
    NSStringFromClass(WordPressAppDelegate.self)
)
