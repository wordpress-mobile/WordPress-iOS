import Foundation

struct LockScreenWidgetViewModelMapper {
    func getLockScreenSingleStatViewModel(
        data: LockScreenStatsWidgetData,
        title: String
    ) -> LockScreenSingleStatViewModel {
        LockScreenSingleStatViewModel(
            siteName: data.siteName,
            title: title,
            value: data.views ?? 0,
            updatedTime: data.date
        )
    }

    func getLockScreenUnconfiguredViewModel(_ message: String) -> LockScreenUnconfiguredViewModel {
        LockScreenUnconfiguredViewModel(message: message)
    }
}
