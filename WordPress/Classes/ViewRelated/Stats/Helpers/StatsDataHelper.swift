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
