import SwiftUI
import WidgetKit
import JetpackStatsWidgetsCore

protocol LockScreenStatsWidgetsViewProvider<Data> {
    associatedtype SiteSelectedView: View
    associatedtype LoggedOutView: View
    associatedtype NoSiteView: View
    associatedtype NoDataView: View
    associatedtype Data: HomeWidgetData

    @ViewBuilder
    func buildSiteSelectedView(_ data: Data) -> SiteSelectedView

    @ViewBuilder
    func buildLoggedOutView() -> LoggedOutView

    @ViewBuilder
    func buildNoSiteView() -> NoSiteView

    @ViewBuilder
    func buildNoDataView() -> NoDataView
}

struct LockScreenStatsWidgetsView<T: LockScreenStatsWidgetsViewProvider>: View {
    let timelineEntry: LockScreenStatsWidgetEntry<T.Data>
    let viewProvider: T

    @ViewBuilder
    var body: some View {
        switch timelineEntry {
        case let .siteSelected(data, _):
            viewProvider
                .buildSiteSelectedView(data)
                .widgetURL(data.statsURL?.appendingSource(.lockScreenWidget))
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
