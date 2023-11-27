import JetpackStatsWidgetsCore

// MARK: - Local cache

extension HomeWidgetData {

    static func read(from cache: HomeWidgetCache<Self>? = nil) -> [Int: Self]? {

        let cache = cache ?? HomeWidgetCache<Self>(fileName: Self.filename,
                                                                  appGroup: WPAppGroupName)
        do {
            return try cache.read()
        } catch {
            DDLogError("HomeWidgetToday: Failed loading data: \(error.localizedDescription)")
            return nil
        }
    }

    static func write(items: [Int: Self], to cache: HomeWidgetCache<Self>? = nil) {

        let cache = cache ?? HomeWidgetCache<Self>(fileName: Self.filename,
                                                                  appGroup: WPAppGroupName)

        do {
            try cache.write(items: items)
        } catch {
            DDLogError("HomeWidgetToday: Failed writing data: \(error.localizedDescription)")
        }
    }

    static func delete(cache: HomeWidgetCache<Self>? = nil) {
        let cache = cache ?? HomeWidgetCache<Self>(fileName: Self.filename,
                                                                  appGroup: WPAppGroupName)

        do {
            try cache.delete()
        } catch {
            DDLogError("HomeWidgetToday: Failed deleting data: \(error.localizedDescription)")
        }
    }

    static func setItem(item: Self, to cache: HomeWidgetCache<Self>? = nil) {
        let cache = cache ?? HomeWidgetCache<Self>(fileName: Self.filename,
                                                                  appGroup: WPAppGroupName)

        do {
            try cache.setItem(item: item)
        } catch {
            DDLogError("HomeWidgetToday: Failed writing data item: \(error.localizedDescription)")
        }
    }

    static func cacheDataExists() -> Bool {
        let data = read()
        return data != nil && data?.isEmpty == false
    }
}
