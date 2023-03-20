import SwiftUI
import WidgetKit

protocol LockScreenStatsWidgetsViewProvider {
    associatedtype SiteSelectedView: View
    associatedtype LoggedOutView: View
    associatedtype NoSiteView: View
    associatedtype NoDataView: View

    @ViewBuilder
    func buildSiteSelectedView(_ data: HomeWidgetData) -> SiteSelectedView

    @ViewBuilder
    func buildLoggedOutView() -> LoggedOutView

    @ViewBuilder
    func buildNoSiteView() -> NoSiteView

    @ViewBuilder
    func buildNoDataView() -> NoDataView

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
        case .loggedOut:
            viewProvider
                .buildLoggedOutView()
                .widgetURL(nil)
        case .noSite:
            viewProvider
                .buildNoSiteView()
                .widgetURL(nil)
        case .noData:
            viewProvider
                .buildNoDataView()
                .widgetURL(nil)
        case .disabled:
            // TODO: Remove disabled case when adding lock screen TimeLineProvider and Entry
            // Lock Screen widget should not have disable status
            EmptyView()
        }
    }
}
