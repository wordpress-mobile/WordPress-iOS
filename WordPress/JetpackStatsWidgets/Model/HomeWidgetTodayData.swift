
struct HomeWidgetTodayData: HomeWidgetData {

    let siteID: Int
    let siteName: String
    let url: String
    let timeZone: TimeZone
    let date: Date
    let stats: TodayWidgetStats
    static let filename = AppConfiguration.Widget.Stats.todayFilename

    var statsURL: URL? {
        guard let statsUrl = URL(string: "https://wordpress.com/stats/day/") else {
            return nil
        }
        return statsUrl.appendingPathComponent(String(siteID))
    }
}
