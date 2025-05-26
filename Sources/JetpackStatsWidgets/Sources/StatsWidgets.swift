import SwiftUI
import WidgetKit
import BuildSettingsKit

@main
struct JetpackStatsWidgets: WidgetBundle {
    init() {
        BuildSettings.configure(secrets: ApiCredentials.toSecrets())
    }

    var body: some Widget {
        HomeWidgetToday()
        HomeWidgetThisWeek()
        HomeWidgetAllTime()
        LockScreenStatsWidget(config: LockScreenTodayViewsStatWidgetConfig())
        LockScreenStatsWidget(config: LockScreenTodayViewsVisitorsStatWidgetConfig())
        LockScreenStatsWidget(config: LockScreenTodayLikesCommentsStatWidgetConfig())
        LockScreenStatsWidget(config: LockScreenAllTimeViewsStatWidgetConfig())
        LockScreenStatsWidget(config: LockScreenAllTimeViewsVisitorsStatWidgetConfig())
        LockScreenStatsWidget(config: LockScreenAllTimePostsBestViewsStatWidgetConfig())
    }
}

private extension ApiCredentials {

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
