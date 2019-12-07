import Foundation

/// This struct contains data for 'Views This Week' stats to be displayed in the corresponding widget.
/// The data is stored in a plist for the widget to access.
/// This file is shared with WordPressThisWeekWidget, which accesses the data when it is viewed.
///

struct ThisWeekWidgetStats: Codable {
    let days: [ThisWeekWidgetDay]

    private enum CodingKeys: String, CodingKey {
        case days
    }

    init(days: [ThisWeekWidgetDay]? = []) {
        self.days = days ?? []
    }
}

struct ThisWeekWidgetDay: Codable {
    let date: Date
    let viewsCount: Int
    let dailyChange: Int

    private enum CodingKeys: String, CodingKey {
        case date
        case viewsCount
        case dailyChange
    }

    init(date: Date, viewsCount: Int, dailyChange: Int) {
        self.date = date
        self.viewsCount = viewsCount
        self.dailyChange = dailyChange
    }
}

extension ThisWeekWidgetStats {

    static func loadSavedData() -> ThisWeekWidgetStats {
        guard let sharedDataFileURL = dataFileURL,
            FileManager.default.fileExists(atPath: sharedDataFileURL.path) == true else {
                DDLogError("ThisWeekWidgetStats: data file '\(dataFileName)' does not exist.")
                return ThisWeekWidgetStats()
        }

        let decoder = PropertyListDecoder()
        do {
            let data = try Data(contentsOf: sharedDataFileURL)
            return try decoder.decode(ThisWeekWidgetStats.self, from: data)
        } catch {
            DDLogError("Failed loading ThisWeekWidgetStats data: \(error.localizedDescription)")
            return ThisWeekWidgetStats()
        }
    }

    func saveData() {
        guard let dataFileURL = ThisWeekWidgetStats.dataFileURL else {
            return
        }

        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml

        do {
            let data = try encoder.encode(self)
            try data.write(to: dataFileURL)
        } catch {
            DDLogError("Failed saving ThisWeekWidgetStats data: \(error.localizedDescription)")
        }
    }

    private static var dataFileName = "ThisWeekData.plist"

    private static var dataFileURL: URL? {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WPAppGroupName) else {
            return nil
        }
        return url.appendingPathComponent(dataFileName)
    }

}
