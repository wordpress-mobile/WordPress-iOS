import Foundation
import WordPressKit

/// This struct contains data for 'Views This Week' stats to be displayed in the corresponding widget.
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

    static func daysFrom(summaryData: [StatsSummaryData]) -> [ThisWeekWidgetDay] {
        var days = [ThisWeekWidgetDay]()

        for index in 0..<maxDaysToDisplay {
            guard index + 1 < summaryData.endIndex else {
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
