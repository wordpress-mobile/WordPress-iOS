import SwiftUI
import WidgetKit

protocol LockScreenStatsWidgetsViewProvider {
    associatedtype SiteSelectedView: View
    associatedtype LoggedOutView: View
    associatedtype NoSiteView: View
    associatedtype NoDataView: View

    @ViewBuilder
    func buildSiteSelectedView(_ data: LockScreenStatsWidgetData) -> SiteSelectedView

    @ViewBuilder
    func buildLoggedOutView() -> LoggedOutView

    @ViewBuilder
    func buildNoSiteView() -> NoSiteView

    @ViewBuilder
    func buildNoDataView() -> NoDataView
}

struct LockScreenStatsWidgetsView<T: LockScreenStatsWidgetsViewProvider>: View {
    let timelineEntry: LockScreenStatsWidgetEntry
    let viewProvider: T

    @ViewBuilder
    var body: some View {
        switch timelineEntry {
        case let .siteSelected(data, _):
            viewProvider
                .buildSiteSelectedView(data)
                .widgetURL(data.widgetURL)
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
        }
    }
}
