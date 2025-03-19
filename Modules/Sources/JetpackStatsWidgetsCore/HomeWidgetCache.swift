import Foundation

/// Cache manager that stores `HomeWidgetData` values in a plist file, contained in the specified security application group and with the specified file name.
/// The corresponding dictionary is always in the form `[Int: T]`, where the `Int` key is the SiteID, and the `T` value is any `HomeWidgetData` instance.
public struct HomeWidgetCache<T: HomeWidgetData> {
    let fileName: String
    let appGroup: String

    public init(fileName: String = T.filename, appGroup: String) {
        self.fileName = fileName
        self.appGroup = appGroup
    }

    private var fileURL: URL? {
        if appGroup.hasPrefix(Self.testAppGroupNamePrefix) {
            return makeTestingFileURL()
        }
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)?.appendingPathComponent(fileName)
    }

    /// Tests are not eligible to write to shared secure groups.
    private func makeTestingFileURL() -> URL? {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(appGroup)
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        return directoryURL.appendingPathComponent(fileName)
    }

    public func read() throws -> [Int: T]? {
        guard let fileURL, FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: fileURL)
        return try PropertyListDecoder().decode([Int: T].self, from: data)
    }

    public func write(items: [Int: T]) throws {
        guard let fileURL else { return }

        let encodedData = try PropertyListEncoder().encode(items)
        try encodedData.write(to: fileURL)
    }

    public func setItem(item: T) throws {
        var cachedItems = try read() ?? [Int: T]()

        cachedItems[item.siteID] = item

        try write(items: cachedItems)
    }

    public func delete() throws {
        guard let fileURL else { return }
        try FileManager.default.removeItem(at: fileURL)
    }

    public static var testAppGroupNamePrefix: String { "xctest" }
}
