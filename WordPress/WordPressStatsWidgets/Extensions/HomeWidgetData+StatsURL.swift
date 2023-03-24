import Foundation

extension HomeWidgetTodayData {
    static let statsUrl = "https://wordpress.com/stats/day/"

    var statsURL: URL? {
        URL(string: Self.statsUrl + "\(siteID)?source=widget")
    }
}

extension HomeWidgetAllTimeData {
    static let statsUrl = "https://wordpress.com/stats/insights/"

    var statsURL: URL? {
        URL(string: Self.statsUrl + "\(siteID)?source=widget")
    }
}

extension HomeWidgetThisWeekData {
    static let statsUrl = "https://wordpress.com/stats/week/"

    var statsURL: URL? {
        URL(string: Self.statsUrl + "\(siteID)?source=widget")
    }
}
