import Foundation
import WordPressKit

/// This struct contains data for 'Views This Week' stats to be displayed in the corresponding widget.
/// The data is stored in a plist for the widget to access.
/// This file is shared with WordPressThisWeekWidget, which accesses the data when it is viewed.
///

struct ThisWeekWidgetStats: Codable {
    let days: [ThisWeekWidgetDay]

    init(days: [ThisWeekWidgetDay]? = []) {
        self.days = days ?? []
    }
}

struct ThisWeekWidgetDay: Codable, Hashable {
    let date: Date
    let viewsCount: Int
    let dailyChangePercent: Float

    init(date: Date, viewsCount: Int, dailyChangePercent: Float) {
        self.date = date
        self.viewsCount = viewsCount
        self.dailyChangePercent = dailyChangePercent
    }
}

extension ThisWeekWidgetStats {

    static var maxDaysToDisplay: Int {
        return 7
    }

    static func loadSavedData() -> ThisWeekWidgetStats? {
        guard let sharedDataFileURL = dataFileURL,
            FileManager.default.fileExists(atPath: sharedDataFileURL.path) == true else {
                DDLogError("ThisWeekWidgetStats: data file '\(dataFileName)' does not exist.")
                return nil
        }

        let decoder = PropertyListDecoder()
        do {
            let data = try Data(contentsOf: sharedDataFileURL)
            return try decoder.decode(ThisWeekWidgetStats.self, from: data)
        } catch {
            DDLogError("Failed loading ThisWeekWidgetStats data: \(error.localizedDescription)")
            return nil
        }
    }

    static func clearSavedData() {
        guard let dataFileURL = ThisWeekWidgetStats.dataFileURL else {
            return
        }

        do {
            try FileManager.default.removeItem(at: dataFileURL)
        }
        catch {
            DDLogError("ThisWeekWidgetStats: failed deleting data file '\(dataFileName)': \(error.localizedDescription)")
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

    static func daysFrom(summaryData: [StatsSummaryData]) -> [ThisWeekWidgetDay] {

        var days = [ThisWeekWidgetDay]()

        for index in 0..<maxDaysToDisplay {
            guard index + 1 <= summaryData.endIndex else {
                break
            }

            let currentDay = summaryData[index]
            let previousDayCount = summaryData[index + 1].viewsCount
            let difference = currentDay.viewsCount - previousDayCount

            let dailyChangePercent: Float = {
                if previousDayCount > 0 {
                    return (Float(difference) / Float(previousDayCount))
                }
                return 0
            }()

            let widgetData = ThisWeekWidgetDay(date: currentDay.periodStartDate,
                                               viewsCount: currentDay.viewsCount,
                                               dailyChangePercent: dailyChangePercent)
            days.append(widgetData)
        }

        return days
    }

    private static var dataFileName = "ThisWeekData.plist"

    private static var dataFileURL: URL? {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WPAppGroupName) else {
            DDLogError("ThisWeekWidgetStats: unable to get file URL for \(WPAppGroupName).")
            return nil
        }
        return url.appendingPathComponent(dataFileName)
    }

}

extension ThisWeekWidgetStats: Equatable {
    static func == (lhs: ThisWeekWidgetStats, rhs: ThisWeekWidgetStats) -> Bool {
        return lhs.days.elementsEqual(rhs.days)
    }
}

extension ThisWeekWidgetDay: Equatable {
    static func == (lhs: ThisWeekWidgetDay, rhs: ThisWeekWidgetDay) -> Bool {
        return lhs.date == rhs.date &&
        lhs.viewsCount == rhs.viewsCount &&
        lhs.dailyChangePercent == rhs.dailyChangePercent
    }
}
