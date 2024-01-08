import JetpackStatsWidgetsCore

struct HomeWidgetThisWeekData: HomeWidgetData {

    let siteID: Int
    let siteName: String
    let url: String
    let timeZone: TimeZone
    let date: Date
    let stats: ThisWeekWidgetStats
    static let filename = AppConfiguration.Widget.Stats.thisWeekFilename

    var statsURL: URL? {
        guard let statsUrl = URL(string: "https://wordpress.com/stats/week/") else {
            return nil
        }
        return statsUrl.appendingPathComponent(String(siteID))
    }
}
