import Foundation
import Gridicons

/// A view containing weekday symbols horizontally aligned for use in a calendar header
class WeekdaysHeaderView: UIStackView {
    convenience init(calendar: Calendar) {
        /// Adjust the weekday symbols array so that the first week day matches
        let weekdaySymbols = calendar.veryShortWeekdaySymbols.rotateLeft(calendar.firstWeekday - 1)
        self.init(arrangedSubviews: weekdaySymbols.map({ symbol in
            let label = UILabel()
            label.text = symbol
            label.textAlignment = .center
            label.font = UIFont.preferredFont(forTextStyle: .caption1)
            label.textColor = .neutral(.shade30)
            label.isAccessibilityElement = false
            return label
        }))
        self.distribution = .fillEqually
    }
}

extension Collection {
    /// Rotates the array to the left ([1,2,3,4] -> [2,3,4,1])
    /// - Parameter offset: The offset by which to shift the array.
    func rotateLeft(_ offset: Int) -> [Self.Element] {
        let initialDigits = (abs(offset) % self.count)
        let elementToPutAtEnd = Array(self[startIndex..<index(startIndex, offsetBy: initialDigits)])
        let elementsToPutAtBeginning = Array(self[index(startIndex, offsetBy: initialDigits)..<endIndex])
        return elementsToPutAtBeginning + elementToPutAtEnd
    }
}
