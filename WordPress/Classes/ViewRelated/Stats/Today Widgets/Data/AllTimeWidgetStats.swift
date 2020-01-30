import Foundation

/// This struct contains data for the Insights All Time stats to be displayed in the corresponding widget.
/// The data is stored in a plist for the widget to access.
/// This file is shared with WordPressAllTimeWidget, which accesses the data when it is viewed.
///

struct AllTimeWidgetStats: Codable {
    let views: Int
    let visitors: Int
    let posts: Int
    let bestViews: Int

    init(views: Int? = 0, visitors: Int? = 0, posts: Int? = 0, bestViews: Int? = 0) {
        self.views = views ?? 0
        self.visitors = visitors ?? 0
        self.posts = posts ?? 0
        self.bestViews = bestViews ?? 0
    }
}

extension AllTimeWidgetStats {

    static func loadSavedData() -> AllTimeWidgetStats? {
        guard let sharedDataFileURL = dataFileURL,
            FileManager.default.fileExists(atPath: sharedDataFileURL.path) == true else {
                DDLogError("AllTimeWidgetStats: data file '\(dataFileName)' does not exist.")
                return nil
        }

        let decoder = PropertyListDecoder()
        do {
            let data = try Data(contentsOf: sharedDataFileURL)
            return try decoder.decode(AllTimeWidgetStats.self, from: data)
        } catch {
            DDLogError("Failed loading AllTimeWidgetStats data: \(error.localizedDescription)")
            return nil
        }
    }

    static func clearSavedData() {
        guard let dataFileURL = AllTimeWidgetStats.dataFileURL else {
            return
        }

        do {
            try FileManager.default.removeItem(at: dataFileURL)
        }
        catch {
            DDLogError("AllTimeWidgetStats: failed deleting data file '\(dataFileName)': \(error.localizedDescription)")
        }
    }

    func saveData() {
        guard let dataFileURL = AllTimeWidgetStats.dataFileURL else {
                return
        }

        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml

        do {
            let data = try encoder.encode(self)
            try data.write(to: dataFileURL)
        } catch {
            DDLogError("Failed saving AllTimeWidgetStats data: \(error.localizedDescription)")
        }
    }

    private static var dataFileName = "AllTimeData.plist"

    private static var dataFileURL: URL? {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WPAppGroupName) else {
            DDLogError("AllTimeWidgetStats: unable to get file URL for \(WPAppGroupName).")
            return nil
        }
        return url.appendingPathComponent(dataFileName)
    }

}

extension AllTimeWidgetStats: Equatable {
    static func == (lhs: AllTimeWidgetStats, rhs: AllTimeWidgetStats) -> Bool {
        return lhs.views == rhs.views &&
            lhs.visitors == rhs.visitors &&
            lhs.posts == rhs.posts &&
            lhs.bestViews == rhs.bestViews
    }
}
