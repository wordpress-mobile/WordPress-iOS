import Foundation

extension String {

    /// This method can be used to check if the string contains a valid URL.
    ///
    /// - Returns: `true` if the string contains a valid string.  `false` otherwise.
    ///
    public func isValidURL() -> Bool {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

        if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) {
            // it is a link, if the match covers the whole string
            return match.range.length == self.utf16.count
        } else {
            return false
        }
    }
}
