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
            firstField: .init(
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
