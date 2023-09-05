
struct HomeWidgetThisWeekData: HomeWidgetData {

    let siteID: Int
    let siteName: String
    let url: String
    let timeZone: TimeZone
    let date: Date
    let stats: ThisWeekWidgetStats
    static let filename = AppConfiguration.Widget.Stats.thisWeekFilename

    var statsURL: URL? {
        let statsUrl = "https://wordpress.com/stats/week/"
        return URL(string: statsUrl + "\(siteID)")
    }
}
