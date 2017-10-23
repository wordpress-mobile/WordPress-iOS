import Foundation


// MARK: - Range Helpers
//
extension String {

    /// Returns a NSRange instance starting at position 0, with the entire String's Length
    ///
    var foundationRangeOfEntireString: NSRange {
        return NSRange(location: 0, length: utf16.count)
    }
}
