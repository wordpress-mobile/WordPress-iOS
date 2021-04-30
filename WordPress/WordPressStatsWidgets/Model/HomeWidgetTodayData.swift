
struct HomeWidgetTodayData: HomeWidgetData {

    let siteID: Int
    let siteName: String
    let url: String
    let timeZone: TimeZone
    let date: Date
    let stats: TodayWidgetStats
    static let filename = "HomeWidgetTodayData.plist"
}
