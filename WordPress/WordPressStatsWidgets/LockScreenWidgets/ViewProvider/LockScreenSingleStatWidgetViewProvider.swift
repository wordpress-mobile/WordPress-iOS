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
        var message: String {
            switch widgetKind {
            case .today:
                return AppConfiguration.Widget.Localization.unconfiguredViewTodayTitle
            case .allTime:
                return AppConfiguration.Widget.Localization.unconfiguredViewAllTimeTitle
            case .thisWeek:
                return AppConfiguration.Widget.Localization.unconfiguredViewThisWeekTitle
            }
        }
        let viewModel = LockScreenUnconfiguredViewModel(message: message)
        return LockScreenUnconfiguredView(viewModel: viewModel)
    }

    func buildNoSiteView() -> LockScreenUnconfiguredView {
        var message: String {
            switch widgetKind {
            case .today:
                return LocalizableStrings.noSiteViewTodayTitle
            case .allTime:
                return LocalizableStrings.noSiteViewAllTimeTitle
            case .thisWeek:
                return LocalizableStrings.noSiteViewThisWeekTitle
            }
        }
        let viewModel = LockScreenUnconfiguredViewModel(message: message)
        return LockScreenUnconfiguredView(viewModel: viewModel)
    }

    func buildNoDataView() -> LockScreenUnconfiguredView {
        var message: String {
            switch widgetKind {
            case .today:
                return LocalizableStrings.noDataViewTodayTitle
            case .allTime:
                return LocalizableStrings.noDataViewAllTimeTitle
            case .thisWeek:
                return LocalizableStrings.noDataViewThisWeekTitle
            }
        }
        let viewModel = LockScreenUnconfiguredViewModel(message: message)
        return LockScreenUnconfiguredView(viewModel: viewModel)
    }
}
