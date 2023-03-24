import Foundation

struct LockScreenWidgetViewModelMapper {
    let data: LockScreenStatsWidgetData

    func getLockScreenSingleStatViewModel(
        title: String
    ) -> LockScreenSingleStatViewModel {
        LockScreenSingleStatViewModel(
            siteName: getSiteName(),
            title: title,
            value: getViews(),
            updatedTime: data.date
        )
    }

    func getSiteName() -> String {
        data.siteName
    }

    func getViews() -> String {
        data.views?.abbreviatedString() ?? ""
    }
}
