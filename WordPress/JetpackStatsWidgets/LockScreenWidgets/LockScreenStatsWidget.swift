import WidgetKit
import SwiftUI

@available(iOS 16.0, *)
struct LockScreenStatsWidget<T: LockScreenStatsWidgetConfig>: Widget {
    private let tracks = Tracks(appGroupName: WPAppGroupName)
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
            defer {
                tracks.trackWidgetUpdatedIfNeeded(entry: entry,
                                                  widgetKind: config.kind)
            }
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
