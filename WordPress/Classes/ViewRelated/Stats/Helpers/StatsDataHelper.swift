import Foundation


/// Helper class for getting/modifying Stats data for display purposes.
///
class StatsDataHelper {

    // This stores the labels for expanded rows.
    // It is used to track which rows are expanded, so the expanded view can be restored
    // when the cells are recreated (ex: on scrolling).
    // They are segregated by StatType (Insights or Period) for easy access.
    static var expandedRowLabels = [StatType: [String]]()

    class func dataBarPercentForRow(_ row: StatsItem, relativeToRow maxValueRow: StatsItem?) -> Float? {

        // Get value from maxValueRow
        guard let maxValueRow = maxValueRow,
            let maxValueString = maxValueRow.value,
            let rowsMaxValue = maxValueString.statFloatValue() else {
                return nil
        }

        // Get value from row
        guard let rowValueString = row.value,
            let rowValue = rowValueString.statFloatValue() else {
                return nil
        }

        // Return percent
        return rowValue / rowsMaxValue
    }

    class func disclosureUrlForItem(_ statItem: StatsItem) -> URL? {
        let disclosureURL: URL? = {
            if let actions = statItem.actions,
                let action = actions.first as? StatsItemAction {
                return action.url
            }
            return nil
        }()

        return disclosureURL
    }
}

/// These methods format stat Strings for display and usage.
/// Once the backend is updated to provide number values, this extension
/// and all it's usage should no longer be necessary.
///

extension String {

    /// Strips commas from formatting stat Strings and returns the Float value.
    ///
    func statFloatValue() -> Float? {
        return Float(replacingOccurrences(of: ",", with: "", options: NSString.CompareOptions.literal, range: nil))
    }

    /// If the String can be converted to a Float, return the abbreviated format for it.
    /// Otherwise return the original String.
    ///
    func displayString() -> String {
        if let floatValue = statFloatValue() {
            return floatValue.abbreviatedString()
        }

        return self
    }

}

extension Date {
    func relativeStringInPast(timezone: TimeZone = TimeZone.autoupdatingCurrent) -> String {
        // This is basically a Swift rewrite of https://github.com/wordpress-mobile/WordPressCom-Stats-iOS/blob/develop/WordPressCom-Stats-iOS/Services/StatsDateUtilities.m#L97
        // It could definitely use some love!

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timezone

        let now = Date()

        let components = calendar.dateComponents([.minute, .hour, .day], from: self, to: now)
        let niceComponents = calendar.dateComponents([.minute, .hour, .day, .month, .year], from: self, to: now)

        switch (components.day, components.hour, components.minute) {
        case (let day?, _, _) where day >= 548:
            return String(format: NSLocalizedString("%d years", comment: "Age between dates over one year."), niceComponents.year!)
        case (let day?, _, _) where day >= 345:
            return String(format: NSLocalizedString("a year", comment: "Age between dates equaling one year."))
        case (let day?, _, _) where day >= 45:
            return String(format: NSLocalizedString("%d months", comment: "Age between dates over one month."), niceComponents.month!)
        case (let day?, _, _) where day >= 25:
            return String(format: NSLocalizedString("a month", comment: "Age between dates equaling one month"))
        case (let day?, let hour?, _) where (day > 1 || (day == 1 && hour >= 12)):
            return String(format: NSLocalizedString("%d days", comment: "Age between dates over one day."), niceComponents.day!)
        case (_, let hour?, _) where hour >= 22:
            return String(format: NSLocalizedString("a day", comment: "Age between dates equaling one day."))
        case (_, let hour?, let minute?) where (hour > 1 || (hour == 1 && minute >= 30)):
            return String(format: NSLocalizedString("%d hours", comment: "Age between dates over one hour."), niceComponents.hour!)
        case (_, _, let minute?) where minute >= 45:
            return String(format: NSLocalizedString("an hour", comment: "Age between dates equaling one hour."))
        default:
            return NSLocalizedString("<1 hour", comment: "Age between dates less than one hour.")
        }
    }
}
