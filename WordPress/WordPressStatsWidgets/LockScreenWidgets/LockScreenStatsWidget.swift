import WidgetKit
import SwiftUI

@available(iOS 16.0, *)
struct LockScreenStatsWidget<T: LockScreenStatsWidgetConfig>: Widget {
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
            kind: config.kind,
            intent: SelectSiteIntent.self,
            provider: SiteListProvider<T.WidgetData>(
                service: StatsWidgetsService(),
                placeholderContent: config.placeholderContent,
                // TODO: remove widgetKind in creating lock screen widget provider and entry PR
                widgetKind: .today
            )
        ) { (entry: StatsWidgetEntry) -> LockScreenStatsWidgetsView in
            return LockScreenStatsWidgetsView(
                timelineEntry: entry,
                viewProvider: config.viewProvider
            )
        }
        .configurationDisplayName(config.displayName)
        .description(config.description)
        .supportedFamilies(supportedFamilies())
    }
}

@available(iOS 16.0, *)
extension LockScreenStatsWidget {
    // TODO: Move to widget config after PR #20317 merged
    func supportedFamilies() -> [WidgetFamily] {
        guard AppConfiguration.isJetpack, FeatureFlag.lockScreenWidget.enabled else {
            return []
        }
        return config.supportFamilies
    }
}
