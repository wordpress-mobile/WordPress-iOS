import Foundation


/// Helper class for getting/modifying Stats data for display purposes.
///
class StatsDataHelper {

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
