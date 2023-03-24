import Foundation

struct LockScreenWidgetViewModelMapper {
    func getLockScreenSingleStatViewModel(
        data: LockScreenStatsWidgetData,
        title: String
    ) -> LockScreenSingleStatViewModel {
        LockScreenSingleStatViewModel(
            siteName: getSiteName(data),
            title: title,
            value: getViews(data),
            updatedTime: data.date
        )
    }

    func getLockScreenUnconfiguredViewModel(_ message: String) -> LockScreenUnconfiguredViewModel {
        LockScreenUnconfiguredViewModel(message: message)
    }

    private func getSiteName(_ data: LockScreenStatsWidgetData) -> String {
        data.siteName
    }

    private func getViews(_ data: LockScreenStatsWidgetData) -> String {
        data.views?.abbreviatedString() ?? ""
    }
}
