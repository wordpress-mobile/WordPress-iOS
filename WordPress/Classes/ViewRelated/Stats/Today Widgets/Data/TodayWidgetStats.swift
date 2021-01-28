import CocoaLumberjack
import Foundation

/// This struct contains data for the Insights Today stats to be displayed in the corresponding widget.
/// The data is stored in a plist for the widget to access.
/// This file is shared with WordPressTodayWidget, which accesses the data when it is viewed.
///

struct TodayWidgetStats: Codable {
    let views: Int
    let visitors: Int
    let likes: Int
    let comments: Int

    init(views: Int? = 0, visitors: Int? = 0, likes: Int? = 0, comments: Int? = 0) {
        self.views = views ?? 0
        self.visitors = visitors ?? 0
        self.likes = likes ?? 0
        self.comments = comments ?? 0
    }
}

extension TodayWidgetStats {

    static func loadSavedData() -> TodayWidgetStats? {
        guard let sharedDataFileURL = dataFileURL,
            FileManager.default.fileExists(atPath: sharedDataFileURL.path) == true else {
                DDLogError("TodayWidgetStats: data file '\(dataFileName)' does not exist.")
                return nil
        }

        let decoder = PropertyListDecoder()
        do {
            let data = try Data(contentsOf: sharedDataFileURL)
            return try decoder.decode(TodayWidgetStats.self, from: data)
        } catch {
            DDLogError("TodayWidgetStats: Failed loading data: \(error.localizedDescription)")
            return nil
        }
    }

    static func clearSavedData() {
        guard let dataFileURL = TodayWidgetStats.dataFileURL else {
            return
        }

        do {
            try FileManager.default.removeItem(at: dataFileURL)
        }
        catch {
            DDLogError("TodayWidgetStats: failed deleting data file '\(dataFileName)': \(error.localizedDescription)")
        }
    }

    func saveData() {
        guard let dataFileURL = TodayWidgetStats.dataFileURL else {
                return
        }

        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml

        do {
            let data = try encoder.encode(self)
            try data.write(to: dataFileURL)
        } catch {
            DDLogError("Failed saving TodayWidgetStats data: \(error.localizedDescription)")
        }
    }

    private static var dataFileName = "TodayData.plist"

    private static var dataFileURL: URL? {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WPAppGroupName) else {
            DDLogError("TodayWidgetStats: unable to get file URL for \(WPAppGroupName).")
            return nil
        }
        return url.appendingPathComponent(dataFileName)
    }

}

extension TodayWidgetStats: Equatable {
    static func == (lhs: TodayWidgetStats, rhs: TodayWidgetStats) -> Bool {
        return lhs.views == rhs.views &&
            lhs.visitors == rhs.visitors &&
            lhs.likes == rhs.likes &&
            lhs.comments == rhs.comments
    }
}
