import SwiftUI

@available(iOS 16.0, *)
struct LockScreenChartWidgetViewProvider<WidgetData: HomeWidgetData>: LockScreenStatsWidgetsViewProvider {
    typealias SiteSelectedView = LockScreenChartView
    typealias LoggedOutView = LockScreenUnconfiguredView
    typealias NoSiteView = LockScreenUnconfiguredView
    typealias NoDataView = LockScreenUnconfiguredView
    typealias Data = WidgetData

    let title: String
    let value: KeyPath<Data, [ThisWeekWidgetDay]>
    let widgetKind: StatsWidgetKind

    func buildSiteSelectedView(_ data: Data) -> LockScreenChartView {
        let days = data[keyPath: value]
        let viewModel = LockScreenChartViewModel(
            siteName: data.siteName,
            valueTitle: LocalizableStrings.chartViewsLabel,
            emptyChartTitle: title,
            columns: days.map { day in
                LockScreenChartViewModel.Column(date: day.date, value: day.viewsCount)
            },
            updatedTime: data.date
        )

        return LockScreenChartView(viewModel: viewModel)
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
