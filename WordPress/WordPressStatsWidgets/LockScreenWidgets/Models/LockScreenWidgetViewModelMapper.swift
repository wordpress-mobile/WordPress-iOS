import Foundation

struct LockScreenWidgetViewModelMapper {
    let data: HomeWidgetData

    func getLockScreenSingleStatViewModel(title: String, dateRange: String) -> LockScreenSingleStatViewModel {
        LockScreenSingleStatViewModel(
            siteName: getSiteName(),
            title: title,
            value: getViews(),
            dateRange: dateRange,
            updatedTime: data.date
        )
    }

    // TODO: Add `LockScreenStatsWidgetData` in creating lock screen widget provider and entry PR
    // define statsURL, views, date, siteName
    // HomeWidgetTodayData, HomeWidgetAllTimeData, HomeWidgetThisWeekData conform to it
    // to reduce the type converting
    func getStateURL() -> URL? {
        if let todayData = data as? HomeWidgetTodayData {
            return todayData.statsURL
        } else if let allTimeData = data as? HomeWidgetAllTimeData {
            return allTimeData.statsURL
        } else if let thisWeekData = data as? HomeWidgetThisWeekData {
            return thisWeekData.statsURL
        } else {
            return nil
        }
    }

    func getSiteName() -> String {
        data.siteName
    }

    func getViews() -> String {
        if let todayData = data as? HomeWidgetTodayData {
            return todayData.stats.views.abbreviatedString()
        } else if let allTimeData = data as? HomeWidgetAllTimeData {
            return allTimeData.stats.views.abbreviatedString()
        } else {
            return ""
        }
    }
}
