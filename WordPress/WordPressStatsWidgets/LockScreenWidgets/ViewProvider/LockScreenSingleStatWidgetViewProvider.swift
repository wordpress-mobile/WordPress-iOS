import SwiftUI

@available(iOS 16.0, *)
struct LockScreenSingleStatWidgetViewProvider: LockScreenStatsWidgetsViewProvider {
    typealias SiteSelectedView = LockScreenSingleStatView

    func buildSiteSelectedView(_ data: HomeWidgetData) -> LockScreenSingleStatView {
        let mapper = LockScreenWidgetViewModelMapper(data: data)
        let viewModel = mapper.getLockScreenSingleStatViewModel(
            title: LocalizableStrings.viewsInTodayTitle
        )
        return LockScreenSingleStatView(viewModel: viewModel)
    }

    func statsURL(_ data: HomeWidgetData) -> URL? {
        let mapper = LockScreenWidgetViewModelMapper(data: data)
        return mapper.getStatsURL()
    }
}
