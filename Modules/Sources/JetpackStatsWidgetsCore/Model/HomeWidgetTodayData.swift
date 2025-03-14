import Foundation

public struct HomeWidgetTodayData: HomeWidgetData {
    public let siteID: Int
    public let siteName: String
    public let url: String
    public let timeZone: TimeZone
    public let date: Date
    public let stats: TodayWidgetStats
    public static let filename = WidgetStatsConfiguration.todayFilename

    public var statsURL: URL? {
        guard let statsUrl = URL(string: "https://wordpress.com/stats/day/") else {
            return nil
        }
        return statsUrl.appendingPathComponent(String(siteID))
    }

    public init(siteID: Int, siteName: String, url: String, timeZone: TimeZone, date: Date, stats: TodayWidgetStats) {
        self.siteID = siteID
        self.siteName = siteName
        self.url = url
        self.timeZone = timeZone
        self.date = date
        self.stats = stats
    }
}
