import Foundation

/// Helper class for getting/modifying Stats data for display purposes.
///
class StatsDataHelper {

    // Max number of rows to display on Insights and Period stat cards.
    static let maxRowsToDisplay = 6

    // MARK: - Expanded Row Handling

    // These arrays store the labels for expanded rows.
    // They are used to track which rows are expanded, so the expanded view can be restored
    // when the cells are recreated (ex: on scrolling).
    // They are segregated by StatSection for easy access.

    // Period and Insights tables.
    static var expandedRowLabels = [StatSection: [String]]()
    // Details table.
    static var expandedRowLabelsDetails = [StatSection: [String]]()

    // Track when a detail row is updated.
    // Used to determine if the disclosure icon needs animating.
    static var detailRowDisclosureNeedsUpdating: String?

    class func updatedExpandedState(forRow row: StatsTotalRow, inDetails: Bool = false) {

        guard let rowData = row.rowData,
            let statSection = rowData.statSection else {
                return
        }

        var expandedRowsArray = inDetails ? StatsDataHelper.expandedRowLabelsDetails : StatsDataHelper.expandedRowLabels
        var expandedRowLabels = expandedRowsArray[statSection] ?? []

        // Remove from array
        expandedRowLabels = expandedRowLabels.filter { $0 != rowData.name }

        // Remove children from array
        rowData.childRows?.forEach { child in
            expandedRowLabels = expandedRowLabels.filter { $0 != child.name }
        }

        // If expanded, add to array.
        if row.expanded {
            expandedRowLabels.append(rowData.name)
        }

        expandedRowsArray[statSection] = expandedRowLabels

        if inDetails {
            StatsDataHelper.expandedRowLabelsDetails = expandedRowsArray
            detailRowDisclosureNeedsUpdating = rowData.name
        } else {
            StatsDataHelper.expandedRowLabels = expandedRowsArray
        }
    }

    class func clearExpandedInsights() {
        StatSection.allInsights.forEach {
            StatsDataHelper.expandedRowLabels[$0]?.removeAll()
        }
    }

    class func clearExpandedPeriods() {
        StatSection.allPeriods.forEach {
            StatsDataHelper.expandedRowLabels[$0]?.removeAll()
        }
    }

    class func clearExpandedDetails() {
        StatsDataHelper.expandedRowLabelsDetails.removeAll()
    }

    // MARK: - Tags and Categories Support

    class func tagsAndCategoriesIconForKind(_ kind: StatsTagAndCategory.Kind) -> UIImage? {
        switch kind {
        case .folder:
            return Style.imageForGridiconType(.folderMultiple)
        case .category:
            return Style.imageForGridiconType(.folder)
        case .tag:
            return Style.imageForGridiconType(.tag)
        }
    }

    class func childRowsForItems(_ children: [StatsTagAndCategory]) -> [StatsTotalRowData] {
        return children.map {
            StatsTotalRowData.init(name: $0.name,
                                   data: "",
                                   icon: StatsDataHelper.tagsAndCategoriesIconForKind($0.kind),
                                   showDisclosure: true,
                                   disclosureURL: $0.url)
        }
    }

    // MARK: - Post Stats Months & Years Support

    class func maxYearFrom(yearsData: [StatsPostViews]) -> Int? {
        return (yearsData.max(by: { $0.date.year! < $1.date.year! }))?.date.year
    }

    class func minYearFrom(yearsData: [StatsPostViews]) -> Int? {
        return (yearsData.max(by: { $0.date.year! > $1.date.year! }))?.date.year
    }

    class func monthsFrom(yearsData: [StatsPostViews], forYear year: Int) -> [StatsPostViews] {
        // Get months from yearsData for the given year, in descending order.
        return (yearsData.filter({ $0.date.year == year })).sorted(by: { $0.date.month! > $1.date.month! })
    }

    class func totalViewsFrom(monthsData: [StatsPostViews]) -> Int {
        return monthsData.map({$0.viewsCount}).reduce(0, +)
    }

    class func childRowsForYear(_ months: [StatsPostViews]) -> [StatsTotalRowData] {
        return months.map {
            StatsTotalRowData(name: StatsDataHelper.displayMonth(forDate: $0.date),
                              data: $0.viewsCount.abbreviatedString())
        }
    }

    // MARK: - Helpers

    class func currentDateForSite() -> Date {
        let siteTimeZone = SiteStatsInformation.sharedInstance.siteTimeZone ?? .autoupdatingCurrent
        return Date().convert(from: siteTimeZone)
    }
}

fileprivate extension Date {
    func convert(from timeZone: TimeZone, comparedWith target: TimeZone = TimeZone.current) -> Date {
        let delta = TimeInterval(timeZone.secondsFromGMT(for: self) - target.secondsFromGMT(for: self))
        return addingTimeInterval(delta)
    }
}

private extension StatsDataHelper {

    typealias Style = WPStyleGuide.Stats

    static var calendar: Calendar = {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = .autoupdatingCurrent
        return cal
    }()

    static var calendarForSite: Calendar = {
        var cal = StatsDataHelper.calendar
        cal.timeZone = SiteStatsInformation.sharedInstance.siteTimeZone ?? .autoupdatingCurrent
        return cal
    }()

    static var monthFormatter: DateFormatter = {
        let df = DateFormatter()
        df.setLocalizedDateFormatFromTemplate("MMM")
        return df
    }()

    class func displayMonth(forDate date: DateComponents) -> String {
        guard let month = StatsDataHelper.calendar.date(from: date) else {
            return ""
        }

        return StatsDataHelper.monthFormatter.string(from: month)
    }

}

extension Date {

    func normalizedForSite() -> Date {
        let calendar = StatsDataHelper.calendar
        let components = calendar.dateComponents([.day, .month, .year], from: self)
        return calendar.date(from: components) ?? self
    }

    func relativeStringInPast() -> String {
        // This is basically a Swift rewrite of https://github.com/wordpress-mobile/WordPressCom-Stats-iOS/blob/develop/WordPressCom-Stats-iOS/Services/StatsDateUtilities.m#L97
        // It could definitely use some love!

        let calendar = StatsDataHelper.calendar
        let now = StatsDataHelper.currentDateForSite()

        let components = calendar.dateComponents([.minute, .hour, .day], from: self, to: now)
        let days = components.day ?? 0
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0

        if days >= DateBreakpoints.aboutYearAndAHalf {
            return String(format: NSLocalizedString("%d years", comment: "Age between dates over one year."), Int(round(Float(days) / Float(365))))
        }

        if days >= DateBreakpoints.almostAYear {
            return String(format: NSLocalizedString("a year", comment: "Age between dates equaling one year."))
        }

        if days >= DateBreakpoints.monthAndAHalf {
            let components = calendar.dateComponents([.minute, .hour, .day, .month, .year], from: self, to: now)
            let months = components.month ?? 0
            let days = components.day ?? 0
            let adjustedMonths = days > DateBreakpoints.halfAMonth ? months + 1 : months
            return String(format: NSLocalizedString("%d months", comment: "Age between dates over one month."), adjustedMonths)
        }

        if days >= DateBreakpoints.almostAMonth {
            return String(format: NSLocalizedString("a month", comment: "Age between dates equaling one month."))
        }

        if days > 1 || (days == 1 && hours >= DateBreakpoints.halfADay) {
            let totalHours = (days * 24) + hours
            return String(format: NSLocalizedString("%d days", comment: "Age between dates over one day."), Int(round(Float(totalHours) / Float(24))))
        }

        if days == 1 || hours > DateBreakpoints.almostADay {
            return String(format: NSLocalizedString("a day", comment: "Age between dates equaling one day."))
        }

        if hours > 1 || (hours == 1 && minutes >= DateBreakpoints.halfAnHour) {
            let totalMinutes = (hours * 60) + minutes
            return String(format: NSLocalizedString("%d hours", comment: "Age between dates over one hour."), Int(round(Float(totalMinutes) / Float(60))))
        }

        if hours == 1 || minutes >= DateBreakpoints.almostAnHour {
            return String(format: NSLocalizedString("an hour", comment: "Age between dates equaling one hour."))
        }

        return NSLocalizedString("< 1 hour", comment: "Age between dates less than one hour.")
    }

    private struct DateBreakpoints {
        static let aboutYearAndAHalf = 548
        static let almostAYear = 305
        static let monthAndAHalf = 44
        static let halfAMonth = 15
        static let almostAMonth = 25
        static let halfADay = 12
        static let almostADay = 22
        static let halfAnHour = 30
        static let almostAnHour = 45
    }
}

extension StatsPeriodUnit {

    var dateFormatTemplate: String {
        switch self {
        case .day:
            return "MMM d, yyyy"
        case .week:
            return "MMM d"
        case .month:
            return "MMM, yyyy"
        case .year:
            return "yyyy"
        }
    }

    var calendarComponent: Calendar.Component {
        switch self {
        case .day:
            return .day
        case .week:
            return .weekOfYear
        case .month:
            return .month
        case .year:
            return .year
        }
    }

    var description: String {
        switch self {
        case .day: return "day"
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
        }
    }

    static var analyticsPeriodKey: String {
        return "period"
    }

}

extension TimeZone {
    func displayForStats() -> String {
        let seconds = self.secondsFromGMT()
        let hours = seconds / 3600
        let remainingSeconds = seconds - (hours * 3600)
        let minutes = remainingSeconds / 60
        let displayMinutes = minutes > 0 ? ":\(minutes)" : ""
        let sign = hours < 0 ? "-" : "+"

        let timezoneString = NSLocalizedString("Site timezone (UTC%@%d%@)",
                                               comment: "Site timezone offset from UTC. The first %@ is plus or minus. %d is the number of hours. The last %@ is minutes, where applicable. Examples: `Site timezone (UTC+10:30)`, `Site timezone (UTC-8)`.")

        return String.localizedStringWithFormat(timezoneString,
                                                sign,
                                                abs(hours),
                                                displayMinutes)
    }
}
