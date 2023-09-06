import SwiftUI

@available(iOS 16.0, *)
struct LockScreenSingleStatWidgetViewProvider<WidgetData: HomeWidgetData>: LockScreenStatsWidgetsViewProvider {
    typealias SiteSelectedView = LockScreenSingleStatView
    typealias LoggedOutView = LockScreenUnconfiguredView
    typealias NoSiteView = LockScreenUnconfiguredView
    typealias NoDataView = LockScreenUnconfiguredView
    typealias Data = WidgetData

    let title: String
    let value: KeyPath<Data, Int>
    let widgetKind: StatsWidgetKind

    func buildSiteSelectedView(_ data: Data) -> LockScreenSingleStatView {
        let viewModel = LockScreenSingleStatViewModel(
            siteName: data.siteName,
            title: title,
            value: data[keyPath: value],
            updatedTime: data.date
        )

        return LockScreenSingleStatView(viewModel: viewModel)
    }

    func buildLoggedOutView() -> LockScreenUnconfiguredView {
        let message: String
        switch widgetKind {
        case .today:
            message = AppConfiguration.Widget.Localization.unconfiguredViewTodayTitle
        case .allTime:
            message = AppConfiguration.Widget.Localization.unconfiguredViewAllTimeTitle
        case .thisWeek:
            message = AppConfiguration.Widget.Localization.unconfiguredViewThisWeekTitle
        }
        let viewModel = LockScreenUnconfiguredViewModel(message: message)
        return LockScreenUnconfiguredView(viewModel: viewModel)
    }

    func buildNoSiteView() -> LockScreenUnconfiguredView {
        let message: String
        switch widgetKind {
        case .today:
            message = LocalizableStrings.noSiteViewTodayTitle
        case .allTime:
            message = LocalizableStrings.noSiteViewAllTimeTitle
        case .thisWeek:
            message = LocalizableStrings.noSiteViewThisWeekTitle
        }
        let viewModel = LockScreenUnconfiguredViewModel(message: message)
        return LockScreenUnconfiguredView(viewModel: viewModel)
    }

    func buildNoDataView() -> LockScreenUnconfiguredView {
        let message: String
        switch widgetKind {
        case .today:
            message = LocalizableStrings.noDataViewTodayTitle
        case .allTime:
            message = LocalizableStrings.noDataViewAllTimeTitle
        case .thisWeek:
            message = LocalizableStrings.noDataViewThisWeekTitle
        }
        let viewModel = LockScreenUnconfiguredViewModel(message: message)
        return LockScreenUnconfiguredView(viewModel: viewModel)
    }
}
