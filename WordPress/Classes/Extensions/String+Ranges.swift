import Foundation


// MARK: - Range Helpers
//
extension String {

    /// Returns a NSRange instance starting at position 0, with the entire String's Length
    ///
    var foundationRangeOfEntireString: NSRange {
        return NSRange(location: 0, length: utf16.count)
    }

    /// Returns the Substring contained by at specified NSRange
    ///
    func substring(with nsrange: NSRange) -> String? {
        guard let range = nsrange.toRange() else {
            return nil
        }

        let start = UTF16Index(range.lowerBound)
        let end = UTF16Index(range.upperBound)

        return String(utf16[start..<end])
    }

    /// Returns the Swift Range for the specified Foundation Range
    ///
    func range(from nsrange: NSRange) -> Range<Index>? {
        guard let range = nsrange.toRange() else {
            return nil
        }

        let utf16Start = UTF16Index(range.lowerBound)
        let utf16End = UTF16Index(range.upperBound)

        guard let start = Index(utf16Start, within: self), let end = Index(utf16End, within: self) else {
            return nil
        }

        return start..<end
    }
}
