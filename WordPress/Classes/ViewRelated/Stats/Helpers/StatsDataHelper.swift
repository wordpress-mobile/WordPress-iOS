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
        let delta = TimeInterval(siteTimeZone.secondsFromGMT())
        return Date().addingTimeInterval(delta)
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
        var calendar = StatsDataHelper.calendarForSite

        let flags: NSCalendar.Unit = [.day, .month, .year]
        let components = (calendar as NSCalendar).components(flags, from: self)

        var normalized = DateComponents()
        normalized.day = components.day
        normalized.month = components.month
        normalized.year = components.year

        calendar.timeZone = .autoupdatingCurrent
        return calendar.date(from: normalized) ?? self
    }

    func relativeStringInPast() -> String {
        // This is basically a Swift rewrite of https://github.com/wordpress-mobile/WordPressCom-Stats-iOS/blob/develop/WordPressCom-Stats-iOS/Services/StatsDateUtilities.m#L97
        // It could definitely use some love!

        let calendar = StatsDataHelper.calendar
        let now = StatsDataHelper.currentDateForSite()

        let components = calendar.dateComponents([.minute, .hour, .day], from: self, to: now)
        let niceComponents = calendar.dateComponents([.minute, .hour, .day, .month, .year], from: self, to: now)

        let days = components.day ?? 0
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0

        if days >= DateFormattingBreakpoints.aboutYearAndAHalf.rawValue {
            return String(format: NSLocalizedString("%d years", comment: "Age between dates over one year."), niceComponents.year!)
        }

        if days >= DateFormattingBreakpoints.almostAYear.rawValue {
            return String(format: NSLocalizedString("a year", comment: "Age between dates equaling one year."))
        }

        if days >= DateFormattingBreakpoints.monthAndAHalf.rawValue {
            return String(format: NSLocalizedString("%d months", comment: "Age between dates over one month."), niceComponents.month!)
        }

        if days >= DateFormattingBreakpoints.almostAMonth.rawValue {
            return String(format: NSLocalizedString("a month", comment: "Age between dates equaling one month"))
        }

        if days > 1 || (days == 1 && hours >= DateFormattingBreakpoints.halfADay.rawValue) {
            return String(format: NSLocalizedString("%d days", comment: "Age between dates over one day."), niceComponents.day!)
        }

        if hours > DateFormattingBreakpoints.almostADay.rawValue {
            return String(format: NSLocalizedString("a day", comment: "Age between dates equaling one day."))
        }

        if hours > 1 || (hours == 1 && minutes >= DateFormattingBreakpoints.halfAnHour.rawValue) {
            return String(format: NSLocalizedString("%d hours", comment: "Age between dates over one hour."), niceComponents.hour!)
        }

        if minutes >= DateFormattingBreakpoints.almostAnHour.rawValue {
            return String(format: NSLocalizedString("an hour", comment: "Age between dates equaling one hour."))
        }

        return NSLocalizedString("<1 hour", comment: "Age between dates less than one hour.")


    }

    private enum DateFormattingBreakpoints: Int {
        case aboutYearAndAHalf = 548
        case almostAYear = 345
        case monthAndAHalf = 35
        case almostAMonth = 25
        case halfADay = 12
        case almostADay = 22
        case halfAnHour = 30
        case almostAnHour = 45
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
        var identifier = self.identifier

        // minutes
        let minutes = Int(identifier.suffix(2)) ?? 0
        identifier.removeLast(2)
        let displayMinutes = minutes > 0 ? ":\(minutes)" : ""

        // hours
        let hours = Int(identifier.suffix(2)) ?? 0
        identifier.removeLast(2)

        // sign
        let sign = String(identifier.removeLast())

        let timezoneString = NSLocalizedString("Site timezone (UTC%@%d%@)",
                                               comment: "Site timezone offset from UTC. The first %@ is plus or minus. %d is the number of hours. The last %@ is minutes, where applicable. Examples: `Site timezone (UTC+10:30)`, `Site timezone (UTC-8)`.")

        return String.localizedStringWithFormat(timezoneString,
                                                sign,
                                                hours,
                                                displayMinutes)
    }
}
