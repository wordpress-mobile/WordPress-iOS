
struct HomeWidgetAllTimeData: HomeWidgetData {

    let siteID: Int
    let siteName: String
    let url: String
    let timeZone: TimeZone
    let date: Date
    let stats: AllTimeWidgetStats
    static let filename = AppConfiguration.Widget.Stats.allTimeFilename

    var statsURL: URL? {
        let statsUrl = "https://wordpress.com/stats/insights/"
        return URL(string: statsUrl + "\(siteID)")
    }
}
