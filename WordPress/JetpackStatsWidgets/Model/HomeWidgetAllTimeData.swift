
struct HomeWidgetAllTimeData: HomeWidgetData {

    let siteID: Int
    let siteName: String
    let url: String
    let timeZone: TimeZone
    let date: Date
    let stats: AllTimeWidgetStats
    static let filename = AppConfiguration.Widget.Stats.allTimeFilename

    var statsURL: URL? {
        guard let statsUrl = URL(string: "https://wordpress.com/stats/insights/") else {
            return nil
        }
        return statsUrl.appendingPathComponent(String(siteID))
    }
}
