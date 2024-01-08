import Foundation

/// This struct contains data for 'Views This Week' stats to be displayed in the corresponding widget.
///

public struct ThisWeekWidgetStats: Codable {
    public let days: [ThisWeekWidgetDay]

    public init(days: [ThisWeekWidgetDay]? = []) {
        self.days = days ?? []
    }
}

public struct ThisWeekWidgetDay: Codable, Hashable {
    public let date: Date
    public let viewsCount: Int
    public let dailyChangePercent: Float

    public init(date: Date, viewsCount: Int, dailyChangePercent: Float) {
        self.date = date
        self.viewsCount = viewsCount
        self.dailyChangePercent = dailyChangePercent
    }
}

public extension ThisWeekWidgetStats {
    struct Input {
        public let periodStartDate: Date
        public let viewsCount: Int

        public init(periodStartDate: Date, viewsCount: Int) {
            self.periodStartDate = periodStartDate
            self.viewsCount = viewsCount
        }
    }

    static var maxDaysToDisplay: Int {
        return 7
    }

    static func daysFrom(summaryData: [ThisWeekWidgetStats.Input]) -> [ThisWeekWidgetDay] {
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
    public static func == (lhs: ThisWeekWidgetStats, rhs: ThisWeekWidgetStats) -> Bool {
        return lhs.days.elementsEqual(rhs.days)
    }
}

extension ThisWeekWidgetDay: Equatable {
    public static func == (lhs: ThisWeekWidgetDay, rhs: ThisWeekWidgetDay) -> Bool {
        return lhs.date == rhs.date &&
        lhs.viewsCount == rhs.viewsCount &&
        lhs.dailyChangePercent == rhs.dailyChangePercent
    }
}
