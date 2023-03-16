import SwiftUI
import WidgetKit

protocol LockScreenStatsWidgetsViewProvider {
    associatedtype SiteSelectedView: View

    @ViewBuilder
    func buildSiteSelectedView(_ data: HomeWidgetData) -> SiteSelectedView

    func statsURL(_ data: HomeWidgetData) -> URL?
}

struct LockScreenStatsWidgetsView<T: LockScreenStatsWidgetsViewProvider>: View {
    let timelineEntry: StatsWidgetEntry
    let viewProvider: T

    @ViewBuilder
    var body: some View {
        switch timelineEntry {
        case let .siteSelected(data, _):
            viewProvider
                .buildSiteSelectedView(data)
                .widgetURL(viewProvider.statsURL(data))
        default:
            // TODO: Build view for loggedOut, noSite, noData status
            Text("Build Later")
        }
    }
}
