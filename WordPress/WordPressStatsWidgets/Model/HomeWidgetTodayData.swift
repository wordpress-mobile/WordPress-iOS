
struct HomeWidgetTodayData: HomeWidgetData {

    let siteID: Int
    let siteName: String
    let url: String
    let timeZone: TimeZone
    let date: Date
    let stats: TodayWidgetStats
    static let filename = AppConfiguration.Widget.Stats.todayFilename

    var statsURL: URL? {
        let statsUrl = "https://wordpress.com/stats/day/"
        return URL(string: statsUrl + "\(siteID)")
    }
}
