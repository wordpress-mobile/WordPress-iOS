import WidgetKit
import SwiftUI
import JetpackStatsWidgetsCore
import TracksMini

struct LockScreenStatsWidget<T: LockScreenStatsWidgetConfig>: Widget {
    private let tracks = Tracks()
    private let config: T

    init(config: T) {
        self.config = config
    }

    @available(*, deprecated, renamed: "init(config:)")
    init() {
        fatalError("Please use init(config: SingleStatWidgetConfig) to provide the config")
    }

    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: config.kind.rawValue,
            intent: SelectSiteIntent.self,
            provider: LockScreenSiteListProvider<T.WidgetData>(
                service: StatsWidgetsService(),
                placeholderContent: config.placeholderContent
            )
        ) { (entry: LockScreenStatsWidgetEntry) -> LockScreenStatsWidgetsView in
            return LockScreenStatsWidgetsView(
                timelineEntry: entry,
                viewProvider: config.viewProvider
            )
        }
        .configurationDisplayName(config.displayName)
        .description(config.description)
        .supportedFamilies(config.supportFamilies)
        .iOS17ContentMarginsDisabled() /// Temporarily disable additional iOS17 margins for widgets
    }
}
