import WidgetKit

// TODO - TODAYWIDGET: we might change this and use only one type for all three widgets
/// protocol that generalizes home widgets data
protocol HomeWidgetData: Codable, TimelineEntry {

    associatedtype WidgetStats

    var siteID: Int { get }
    var siteName: String { get }
    var url: String { get }
    var timeZoneName: String { get }
    var date: Date { get }
    var stats: WidgetStats { get }
}


// TODO - TODAYWIDGET: we might change this and use only one type for all three widgets
/// Type that contains all the relevant data of a Today Home Wifget
struct HomeWidgetTodayData: HomeWidgetData {

    typealias WidgetStats = TodayWidgetStats

    let siteID: Int
    let siteName: String
    let iconURL: String?
    let url: String
    let timeZoneName: String
    let date: Date
    let stats: WidgetStats
}


// MARK: - Local cache
extension HomeWidgetTodayData {

    static func read(from cache: HomeWidgetCache<Self>? = nil) -> [Int: HomeWidgetTodayData]? {

        let cache = cache ?? HomeWidgetCache<HomeWidgetTodayData>(fileName: Constants.fileName,
                                                                  appGroup: WPAppGroupName)
        do {
            return try cache.read()
        } catch {
            DDLogError("HomeWidgetToday: Failed loading data: \(error.localizedDescription)")
            return nil
        }
    }

    static func write(data: [Int: HomeWidgetTodayData], to cache: HomeWidgetCache<Self>? = nil) {

        let cache = cache ?? HomeWidgetCache<HomeWidgetTodayData>(fileName: Constants.fileName,
                                                                  appGroup: WPAppGroupName)

        do {
            try cache.write(widgetData: data)
        } catch {
            DDLogError("HomeWidgetToday: Failed writing data: \(error.localizedDescription)")
        }
    }

    static func delete(cache: HomeWidgetCache<Self>? = nil) {
        let cache = cache ?? HomeWidgetCache<HomeWidgetTodayData>(fileName: Constants.fileName,
                                                                  appGroup: WPAppGroupName)

        do {
            try cache.delete()
        } catch {
            DDLogError("HomeWidgetToday: Failed deleting data: \(error.localizedDescription)")
        }
    }
}


// MARK: - Constants
private extension HomeWidgetTodayData {

    enum Constants {
        static let fileName = "HomeWidgetTodayData.plist"
    }
}
