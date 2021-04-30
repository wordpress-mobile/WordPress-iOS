
struct HomeWidgetThisWeekData: HomeWidgetData {

    let siteID: Int
    let siteName: String
    let url: String
    let timeZone: TimeZone
    let date: Date
    let stats: ThisWeekWidgetStats
    static let filename = "HomeWidgetThisWeekData.plist"
}
