import SwiftUI

@available(iOS 16.0, *)
struct LockScreenSingleStatWidgetViewProvider: LockScreenStatsWidgetsViewProvider {
    typealias SiteSelectedView = LockScreenSingleStatView
    typealias LoggedOutView = Text
    typealias NoSiteView = Text
    typealias NoDataView = Text

    let title: String

    func buildSiteSelectedView(_ data: HomeWidgetData) -> LockScreenSingleStatView {
        let mapper = LockScreenWidgetViewModelMapper(data: data)
        let viewModel = mapper.getLockScreenSingleStatViewModel(
            title: title
        )
        return LockScreenSingleStatView(viewModel: viewModel)
    }

    func statsURL(_ data: HomeWidgetData) -> URL? {
        let mapper = LockScreenWidgetViewModelMapper(data: data)
        return mapper.getStatsURL()
    }

    // TODO: Build view for loggedOut status
    func buildLoggedOutView() -> Text {
        Text("Build Later")
    }

    // TODO: Build view for noSite status
    func buildNoSiteView() -> Text {
        Text("Build Later")
    }

    // TODO: Build view for noData status
    func buildNoDataView() -> Text {
        Text("Build Later")
    }
}
