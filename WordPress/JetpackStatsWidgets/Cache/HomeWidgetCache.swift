import Foundation

/// Cache manager that stores `HomeWidgetData` values in a plist file, contained in the specified security application group and with the specified file name.
/// The corresponding dictionary is always in the form `[Int: T]`, where the `Int` key is the SiteID, and the `T` value is any `HomeWidgetData` instance.
struct HomeWidgetCache<T: HomeWidgetData> {

    let fileName: String
    let appGroup: String

    private var fileURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)?.appendingPathComponent(fileName)
    }

    func read() throws -> [Int: T]? {

        guard let fileURL = fileURL,
            FileManager.default.fileExists(atPath: fileURL.path) else {
                return nil
        }

        let data = try Data(contentsOf: fileURL)
        return try PropertyListDecoder().decode([Int: T].self, from: data)
    }

    func write(items: [Int: T]) throws {

        guard let fileURL = fileURL else {
                return
        }

        let encodedData = try PropertyListEncoder().encode(items)
        try encodedData.write(to: fileURL)
    }

    func setItem(item: T) throws {
        var cachedItems = try read() ?? [Int: T]()

        cachedItems[item.siteID] = item

        try write(items: cachedItems)
    }

    func delete() throws {

        guard let fileURL = fileURL else {
                return
        }
        try FileManager.default.removeItem(at: fileURL)
    }
}
