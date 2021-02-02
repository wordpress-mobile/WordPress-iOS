
struct HomeWidgetAllTimeData: HomeWidgetData {
    let siteID: Int
    let siteName: String
    let iconURL: String?
    let url: String
    let timeZone: TimeZone
    let date: Date
    let stats: AllTimeWidgetStats
    static let filename = "HomeWidgetAllTimeData.plist"
}
