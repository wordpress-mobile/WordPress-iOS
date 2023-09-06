import SwiftUI

@available(iOS 16.0, *)
struct LockScreenMultiStatWidgetViewProvider<WidgetData: HomeWidgetData>: LockScreenStatsWidgetsViewProvider {
    typealias SiteSelectedView = LockScreenMultiStatView
    typealias LoggedOutView = LockScreenUnconfiguredView
    typealias NoSiteView = LockScreenUnconfiguredView
    typealias Data = WidgetData

    let widgetKind: StatsWidgetKind

    let topTitle: String
    let topValue: KeyPath<Data, Int>

    let bottomTitle: String
    let bottomValue: KeyPath<Data, Int>

    func buildSiteSelectedView(_ data: Data) -> LockScreenMultiStatView {
        let viewModel = LockScreenMultiStatViewModel(
            siteName: data.siteName,
            updatedTime: data.date,
            primaryField: .init(
                title: topTitle,
                value: data[keyPath: topValue]
            ),
            secondaryField: .init(
                title: bottomTitle,
                value: data[keyPath: bottomValue]
            )
        )
        return LockScreenMultiStatView(viewModel: viewModel)
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
