
struct HomeWidgetTodayData: HomeWidgetData {

    typealias WidgetStats = TodayWidgetStats

    let siteID: Int
    let siteName: String
    let iconURL: String?
    let url: String
    let timeZone: TimeZone
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

    static func write(items: [Int: HomeWidgetTodayData], to cache: HomeWidgetCache<Self>? = nil) {

        let cache = cache ?? HomeWidgetCache<HomeWidgetTodayData>(fileName: Constants.fileName,
                                                                  appGroup: WPAppGroupName)

        do {
            try cache.write(items: items)
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

    static func setItem(item: HomeWidgetTodayData, to cache: HomeWidgetCache<Self>? = nil) {
        let cache = cache ?? HomeWidgetCache<HomeWidgetTodayData>(fileName: Constants.fileName,
                                                                  appGroup: WPAppGroupName)

        do {
            try cache.setItem(item: item)
        } catch {
            DDLogError("HomeWidgetToday: Failed writing data item: \(error.localizedDescription)")
        }

    }
}


// MARK: - Constants
private extension HomeWidgetTodayData {

    enum Constants {
        static let fileName = "HomeWidgetTodayData.plist"
    }
}
