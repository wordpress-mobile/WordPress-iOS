import Foundation

/// This struct contains data for the Insights Today stats to be displayed in the corresponding widget.
/// The data is stored in a plist for the widget to access.
/// This file is shared with WordPressTodayWidget, which accesses the data when it is viewed.
///

struct TodayWidgetStats: Codable {
    let views: Int
    let visitors: Int

    private enum CodingKeys: String, CodingKey {
        case views
        case visitors
    }

    init(views: Int, visitors: Int) {
        self.views = views
        self.visitors = visitors
    }
}

extension TodayWidgetStats {

    static func loadSavedData() -> TodayWidgetStats {
        guard let sharedDataFileURL = dataFileURL,
            FileManager.default.fileExists(atPath: sharedDataFileURL.path) == true else {
                return TodayWidgetStats(views: 0, visitors: 0)
        }

        let decoder = PropertyListDecoder()
        do {
            let data = try Data(contentsOf: sharedDataFileURL)
            return try decoder.decode(TodayWidgetStats.self, from: data)
        } catch {
            DDLogError("Failed loading TodayWidgetStats data: \(error.localizedDescription)")
            return TodayWidgetStats(views: 0, visitors: 0)
        }
    }

    static func saveData(views: Int, visitors: Int) {
        guard let dataFileURL = dataFileURL else {
                return
        }

        let data = TodayWidgetStats(views: views, visitors: visitors)
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml

        do {
            let data = try encoder.encode(data)
            try data.write(to: dataFileURL)
        } catch {
            DDLogError("Failed saving TodayWidgetStats data: \(error.localizedDescription)")
        }
    }

    private static var dataFileURL: URL? {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WPAppGroupName) else {
            return nil
        }
        return url.appendingPathComponent("TodayData.plist")
    }

}
