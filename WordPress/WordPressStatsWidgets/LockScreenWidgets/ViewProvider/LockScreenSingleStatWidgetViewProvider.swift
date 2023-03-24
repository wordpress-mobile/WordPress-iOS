import SwiftUI

@available(iOS 16.0, *)
struct LockScreenSingleStatWidgetViewProvider: LockScreenStatsWidgetsViewProvider {
    typealias SiteSelectedView = LockScreenSingleStatView
    typealias LoggedOutView = LockScreenUnconfiguredView
    typealias NoSiteView = LockScreenUnconfiguredView
    typealias NoDataView = LockScreenUnconfiguredView

    let title: String
    let widgetKind: StatsWidgetKind
    let mapper = LockScreenWidgetViewModelMapper()

    func buildSiteSelectedView(_ data: LockScreenStatsWidgetData) -> LockScreenSingleStatView {
        let viewModel = mapper.getLockScreenSingleStatViewModel(
            data: data,
            title: title
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
        let viewModel = mapper.getLockScreenUnconfiguredViewModel(message)
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
        let viewModel = mapper.getLockScreenUnconfiguredViewModel(message)
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
        let viewModel = mapper.getLockScreenUnconfiguredViewModel(message)
        return LockScreenUnconfiguredView(viewModel: viewModel)
    }
}
